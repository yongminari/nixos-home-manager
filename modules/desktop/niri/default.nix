{ config, pkgs, lib, inputs, ... }:

let
  currentHost = config.local.desktop;
  baseConfig = if currentHost.monitorIdleRefresh.blur then
    lib.replaceStrings [ (builtins.readFile ./blur-default.kdl) ]
      [ "include \"idle-blur.kdl\"\n" ] (builtins.readFile ./config.kdl)
    else builtins.readFile ./config.kdl;
  workspaceAnimation = "spring damping-ratio=0.5 stiffness=450 epsilon=0.0001";

  isLaptop = currentHost.isLaptop;

  outputSelector = side:
    if currentHost.outputs == null then ""
    else currentHost.outputs.${side};

  niri-toggle-floating = pkgs.writeShellApplication {
    name = "niri-toggle-floating";
    runtimeInputs = with pkgs; [ coreutils jq niri util-linux ];
    text = ''
      # 소켓별로 분리하여 Niri 재시작 후 재사용된 창 ID와 섞이지 않게 합니다.
      : "''${XDG_RUNTIME_DIR:?}" "''${NIRI_SOCKET:?}"
      umask 077
      state_dir="$XDG_RUNTIME_DIR/niri-toggle-floating-''${NIRI_SOCKET##*/}"
      mkdir -p "$state_dir"
      exec 9>"$state_dir/lock"
      flock 9

      window=$(niri msg --json focused-window)
      id=$(jq -r '.id // empty' <<< "$window")
      if [ -z "$id" ]; then
        exit 0
      fi
      saved_size="$state_dir/$id.json"

      if jq -e '.is_floating' <<< "$window" >/dev/null; then
        niri msg action move-window-to-tiling --id "$id"
        # 처음부터 플로팅이었던 창에는 복원할 타일 크기가 없습니다.
        if [ -f "$saved_size" ] && jq -e --argjson window "$window" \
          '.pid == $window.pid' "$saved_size" >/dev/null; then
          read -r width height < <(jq -r '.size | @tsv' "$saved_size")
          niri msg action set-window-width --id "$id" "$width"
          niri msg action set-window-height --id "$id" "$height"
        fi
        rm -f "$saved_size"
        exit 0
      fi

      # 플로팅에서 수동으로 크기를 바꾸더라도 전환 직전 크기를 복원합니다.
      jq '{pid, size: .layout.window_size}' <<< "$window" > "$saved_size.tmp"
      mv "$saved_size.tmp" "$saved_size"

      # %-지정은 화면 기준이므로 전환 직전 창의 논리 픽셀 크기로 계산합니다.
      read -r width height < <(jq -r '
        .layout.window_size | map((. * 0.9 | round) | if . < 1 then 1 else . end) | @tsv
      ' <<< "$window")

      # 크기 변경에는 공통 window-resize 스프링과 탄성 셰이더가 적용됩니다.
      niri msg action move-window-to-floating --id "$id"
      niri msg action set-window-width --id "$id" "$width"
      niri msg action set-window-height --id "$id" "$height"

      # 크기 요청은 비동기입니다. 첫 전환에서 이전 크기로 정렬하지 않도록
      # 앱이 새 크기를 반영한 뒤 테두리를 포함한 실제 크기로 중앙 정렬합니다.
      for ((attempt = 0; attempt < 100; attempt++)); do
        current=$(niri msg --json windows | jq -c --argjson id "$id" \
          'first(.[] | select(.id == $id)) // null')
        if ! jq -e '.is_floating == true' <<< "$current" >/dev/null; then
          exit 0
        fi
        if jq -e --argjson width "$width" --argjson height "$height" \
          '.layout.window_size == [$width, $height]' <<< "$current" >/dev/null; then
          break
        fi
        sleep 0.02
      done
      # 최소 크기 등으로 요청을 거부한 앱도 실제 크기를 기준으로 정렬합니다.
      niri msg action center-window --id "$id"
    '';
  };

  niri-output-toggle = pkgs.writeShellApplication {
    name = "niri-output-toggle";
    runtimeInputs = with pkgs; [ jq libnotify niri python3 util-linux ];
    text = ''
      # 연속 입력으로 작업공간 이동과 출력 비활성화가 겹치지 않게 합니다.
      : "''${XDG_RUNTIME_DIR:?}"
      exec 9>"$XDG_RUNTIME_DIR/niri-output-toggle.lock"
      flock 9

      side="''${1:-}"

      case "$side" in
        left)
          target=${lib.escapeShellArg (outputSelector "left")}
          fallback=${lib.escapeShellArg (outputSelector "right")}
          label="왼쪽"
          ;;
        right)
          target=${lib.escapeShellArg (outputSelector "right")}
          fallback=${lib.escapeShellArg (outputSelector "left")}
          label="오른쪽"
          ;;
        *)
          notify-send -u critical "모니터 전환" "left 또는 right를 지정해야 합니다."
          exit 2
          ;;
      esac

      if [ -z "$target" ] || [ -z "$fallback" ]; then
        notify-send -u normal "모니터 전환" "이 호스트에는 좌·우 모니터가 설정되어 있지 않습니다."
        exit 1
      fi

      if ! outputs=$(niri msg --json outputs); then
        notify-send -u critical "모니터 전환" "Niri 출력 상태를 읽지 못했습니다."
        exit 1
      fi

      resolve_output() {
        jq -r --arg selector "$1" '
          first(
            to_entries[]
            | select(
                .key == $selector
                or .value.name == $selector
                or ([.value.make, .value.model, .value.serial]
                    | map(. // "Unknown")
                    | join(" ")) == $selector
              )
            | .key
          ) // empty
        ' <<< "$outputs"
      }

      target_name=$(resolve_output "$target")
      fallback_name=$(resolve_output "$fallback")

      if [ -z "$target_name" ]; then
        notify-send -u normal "모니터 전환" "$label 모니터가 연결되어 있지 않습니다."
        exit 1
      fi

      if jq -e --arg output "$target_name" '.[$output].current_mode != null' <<< "$outputs" >/dev/null; then
        if [ -z "$fallback_name" ] \
          || ! jq -e --arg output "$fallback_name" '.[$output].current_mode != null' <<< "$outputs" >/dev/null; then
          notify-send -u critical "모니터 전환" "마지막 활성 모니터는 끄지 않습니다."
          exit 1
        fi

        if ! python3 ${./evacuate-output.py} "$target_name" "$fallback_name"; then
          notify-send -u critical "모니터 전환" "창 이동을 완료하지 못해 모니터를 켜 둡니다."
          exit 1
        fi
        niri msg action focus-monitor "$fallback_name"

        niri msg output "$target_name" off
        notify-send -u low "모니터 전환" "$label 모니터를 비활성화했습니다."
      else
        niri msg output "$target_name" on
        notify-send -u low "모니터 전환" "$label 모니터를 활성화했습니다."
      fi
    '';
  };
in
{
  imports = [ ./monitor-flash.nix ./workspace-warp.nix ./adaptive-close.nix ];

  # 모든 장비에 공통 적용하며 호스트 설정에서 개별적으로 재정의할 수 있습니다.
  local.desktop = {
    workspaceWarp.enable = lib.mkDefault true;
    windowAnimation = lib.mkDefault "glass-pressure";
    adaptiveGenieClose = lib.mkDefault false;
  };

  home.packages = with pkgs; [
    niri
    niri-toggle-floating
    niri-output-toggle
    xwayland-satellite
  ];

  wayland.systemd.target = "graphical-session.target";

  # 쓰기 가능한 상태 파일은 최초 활성화 때만 생성하고 이후 토글 상태를 보존합니다.
  home.activation.initializeNiriTouchpad = lib.mkIf isLaptop (
    lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${pkgs.bash}/bin/bash ${../../../scripts/initialize-niri-touchpad.sh} \
        ${lib.escapeShellArg "${config.xdg.configHome}/niri/touchpad-control.kdl"} \
        ${./touchpad-default.kdl}
    ''
  );

  # 터치패드 토글 스크립트 (랩탑일 경우에만 생성)
  xdg.configFile."niri/toggle-touchpad.sh" = lib.mkIf isLaptop {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      INPUT_CONFIG="$HOME/.config/niri/touchpad-control.kdl"
      if grep -q "off" "$INPUT_CONFIG" 2>/dev/null; then
          printf "input {\n    touchpad {\n        tap\n        natural-scroll\n    }\n}\n" > "$INPUT_CONFIG"
          notify-send -t 1500 -i input-touchpad "Touchpad" "Enabled"
      else
          printf "input {\n    touchpad {\n        off\n    }\n}\n" > "$INPUT_CONFIG"
          notify-send -t 1500 -i input-touchpad "Touchpad" "Disabled"
      fi
      niri msg action load-config-file
    '';
  };

  # 메인 설정 파일
  xdg.configFile."niri/config.kdl".text = ''
    // 기본 출력 설정 (스케일 등)
    output "^.*$" {
        scale ${currentHost.scale}
    }

    // 호스트별 추가 출력 설정 (배치 등)
    ${currentHost.extraConfig}

    ${baseConfig}
    ${lib.optionalString currentHost.monitorIdleRefresh.blur ''
      layer-rule {
        match namespace="^niri-idle-blur$"
        background-effect {
          blur true
          xray false
        }
      }
    ''}

    // 창은 위에서 본 먼지 폭발로 나타나고, 닫힐 때는 호스트별 효과를 사용합니다.
    animations {
      // 이동 애니메이션의 속도감을 통일합니다.
      workspace-switch {
        ${workspaceAnimation}
      }
      horizontal-view-movement {
        ${workspaceAnimation}
      }
      window-movement {
        ${workspaceAnimation}
      }
      window-resize {
        // 중앙 우선 변형을 전체 스프링 반동으로 연결합니다.
        spring damping-ratio=0.5 stiffness=180 epsilon=0.0001
        custom-shader r#"
          ${builtins.readFile ./elastic-resize.glsl}
        "#
      }
      config-notification-open-close {
        ${workspaceAnimation}
      }
      exit-confirmation-open-close {
        ${workspaceAnimation}
      }
      screenshot-ui-open {
        ${workspaceAnimation}
      }
      overview-open-close {
        ${workspaceAnimation}
      }
      recent-windows-close {
        ${workspaceAnimation}
      }
      window-open {
        duration-ms 1000
        curve "linear"
        custom-shader r#"
          ${builtins.readFile ./dust-explosion-open.glsl}
        "#
      }
      ${lib.concatMapStringsSep "\n" (action: ''
        window-${action} {
          ${if currentHost.windowAnimation == "glass-pressure" then ''
            duration-ms 1700
            curve "linear"
          '' else if currentHost.windowAnimation == "glacier" then ''
            duration-ms 1250
            curve "linear"
          '' else if currentHost.windowAnimation == "ink" then ''
            duration-ms 900
            curve "linear"
          '' else if currentHost.windowAnimation == "black-hole" then ''
            duration-ms 750
            curve "linear"
          '' else if currentHost.windowAnimation == "genie" then ''
            duration-ms 750
            curve "linear"
          '' else builtins.readFile "${inputs.niri-shaders}/smoke/config"}
          custom-shader r#"
            ${if currentHost.windowAnimation == "glass-pressure" then
              builtins.readFile ./glass-pressure-close.glsl
            else if currentHost.windowAnimation == "glacier" then
              builtins.readFile ./glacier-close.glsl
            else if builtins.elem currentHost.windowAnimation [ "black-hole" "ink" ] then
              lib.optionalString (currentHost.windowAnimation == "ink") "#define INK_FLOW\n"
              + builtins.readFile ./black-hole-close.glsl
            else if currentHost.windowAnimation == "genie" then ''
              ${builtins.readFile ./genie.glsl}
              vec4 ${action}_color(vec3 coords_geo, vec3 size_geo) {
                  return genie_color(coords_geo, size_geo,
                      niri_clamped_progress, 1.0);
              }
            '' else builtins.readFile "${inputs.niri-shaders}/smoke/${action}.glsl"}
          "#
        }
      '') (if currentHost.adaptiveGenieClose then [ ] else [ "close" ])}
    }
    ${lib.optionalString currentHost.adaptiveGenieClose ''
    include "genie-close.kdl"
    ''}
    
    input {
        keyboard {
            xkb { layout "us"; }
            repeat-delay 400
            repeat-rate 40
        }
    }

    ${lib.optionalString isLaptop ''
    // 랩탑 전용 입력 설정 (터치패드)
    include "touchpad-control.kdl"
    ''}
  '';

  xdg.configFile."niri/binds.kdl".text = lib.replaceStrings
    [ "Mod+Q { close-window; }" ]
    [ (if currentHost.adaptiveGenieClose then ''Mod+Q { spawn "niri-adaptive-close"; }'' else "Mod+Q { close-window; }") ]
    (builtins.readFile ./binds.kdl);
}
