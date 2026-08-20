{ config, pkgs, lib, osConfig, ... }:

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
  home.packages = with pkgs; [
    niri
    niri-output-toggle
    xwayland-satellite
  ];

  wayland.systemd.target = "graphical-session.target";

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
