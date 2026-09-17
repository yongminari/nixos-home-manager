{ config, pkgs, lib, inputs, osConfig, ... }:

let
  hostname = osConfig.networking.hostName or "";
  
  # 호스트별 메타데이터 및 설정
  hostRegistry = {
    galaxy-book = {
      scale = "1.0";
      deviceType = "laptop";
      outputs = null;
      extraConfig = "";
    };
    ai-x1-pro = {
      scale = "1.0";
      deviceType = "desktop";
      outputs = {
        left = "Hexium Ltd. 40LGD5KGM 0000000000000";
        right = "Samsung Electric Company SAMSUNG Unknown";
      };
      extraConfig = ''
        output "Hexium Ltd. 40LGD5KGM 0000000000000" {
            mode "5120x2160@120"
            scale 1.25
            position x=0 y=0
        }
        output "Samsung Electric Company SAMSUNG Unknown" {
            off
            mode "3840x2160@60"
            scale 1.25
            position x=4096 y=0
        }
      '';
    };
    nxtp-office-desktop = {
      scale = "1.0";
      deviceType = "desktop";
      outputs = {
        left = "DP-2";
        right = "DP-3";
      };
      # 모니터 좌우 배치 변경: DP-2(왼쪽), DP-3(오른쪽)
      # 깜빡임 이슈 해결을 위해 주사율을 120Hz로 하향 조정
      extraConfig = ''
        output "DP-2" {
            mode "2560x1440@120"
            position x=0 y=0
        }
        output "DP-3" {
            mode "2560x1440@120"
            position x=2560 y=0
        }
      '';
    };
  };

  currentHost = hostRegistry.${hostname} or {
    scale = "1.0";
    deviceType = "desktop";
    outputs = null;
    extraConfig = "";
  };
  baseConfig = builtins.readFile ./config.kdl;

  isLaptop = currentHost.deviceType == "laptop";

  selectIbusHangul = pkgs.writeShellScript "select-ibus-hangul" ''
    for attempt in {1..100}; do
      if ${osConfig.i18n.inputMethod.package}/bin/ibus engine hangul >/dev/null 2>&1; then
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 0.1
    done

    echo "IBus Hangul engine did not become ready" >&2
    exit 1
  '';

  outputSelector = side:
    if currentHost.outputs == null then ""
    else currentHost.outputs.${side};

  niri-output-toggle = pkgs.writeShellApplication {
    name = "niri-output-toggle";
    runtimeInputs = with pkgs; [ jq libnotify niri ];
    text = ''
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

        focused=$(niri msg --json focused-output | jq -r '.name // empty')
        if [ "$focused" = "$target_name" ]; then
          niri msg action focus-monitor "$fallback_name"
        fi

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
  imports = [ ./monitor-flash.nix ];

  home.packages = with pkgs; [
    niri
    niri-output-toggle
    xwayland-satellite
  ];

  wayland.systemd.target = "graphical-session.target";

  # NixOS의 기본 IBus 자동 시작은 X11용 daemon 명령을 사용하므로 사용자 범위에서 가립니다.
  xdg.configFile."autostart/ibus-daemon.desktop" = {
    text = ''
      [Desktop Entry]
      Hidden=true
    '';
  };

  # IBus 1.5.32+의 Wayland input-method-v2 프런트엔드를 Niri 세션에서만 시작합니다.
  xdg.configFile."autostart/ibus-wayland.desktop" = {
    text = ''
      [Desktop Entry]
      Name=IBus Wayland
      Type=Application
      Exec=${osConfig.i18n.inputMethod.package}/bin/ibus start --type wayland
      OnlyShowIn=niri;
      NoDisplay=true
    '';
  };

  # IBus daemon 준비 후 Hangul 엔진을 선택합니다. preload만으로는 전역 엔진이 설정되지 않습니다.
  xdg.configFile."autostart/ibus-hangul.desktop" = {
    text = ''
      [Desktop Entry]
      Name=IBus Hangul Engine
      Type=Application
      Exec=${selectIbusHangul}
      OnlyShowIn=niri;
      NoDisplay=true
    '';
  };

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

    // liixini/shaders의 smoke 효과를 원본 설정과 함께 사용합니다.
    animations {
      // 바운스가 짧고 빠르게 끝나도록 감쇠와 강성을 높입니다.
      // 워크스페이스 전환에도 좌우 스크롤과 같은 탄성을 줍니다.
      workspace-switch {
        spring damping-ratio=0.5 stiffness=800 epsilon=0.0001
      }
      // 좌우 스크롤 끝에 눈에 띄는 탄성을 줍니다.
      horizontal-view-movement {
        spring damping-ratio=0.5 stiffness=800 epsilon=0.0001
      }
      // 창을 합치거나 분리할 때 이동과 크기 변경에 같은 탄성을 줍니다.
      window-movement {
        spring damping-ratio=0.5 stiffness=800 epsilon=0.0001
      }
      window-resize {
        spring damping-ratio=0.5 stiffness=800 epsilon=0.0001
      }
      ${lib.concatMapStringsSep "\n" (action: ''
        window-${action} {
          ${builtins.readFile "${inputs.niri-shaders}/smoke/config"}
          custom-shader r#"
            ${builtins.readFile "${inputs.niri-shaders}/smoke/${action}.glsl"}
          "#
        }
      '') [ "open" "close" ]}
    }
    
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

  xdg.configFile."niri/binds.kdl".source = ./binds.kdl;
}
