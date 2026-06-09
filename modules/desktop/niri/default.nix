{ config, pkgs, lib, osConfig, ... }:

let
  hostname = osConfig.networking.hostName or "";
  
  # 호스트별 메타데이터 및 설정
  hostRegistry = {
    galaxy-book = {
      scale = "1.0";
      deviceType = "laptop";
      extraConfig = "";
    };
    ai-x1-pro = {
      scale = "1.0";
      deviceType = "desktop";
      extraConfig = "";
    };
    nxtp-office-desktop = {
      scale = "1.0";
      deviceType = "desktop";
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

  currentHost = hostRegistry.${hostname} or { scale = "1.0"; deviceType = "desktop"; extraConfig = ""; };
  baseConfig = builtins.readFile ./config.kdl;
  
  isLaptop = currentHost.deviceType == "laptop";
in
{
  home.packages = with pkgs; [
    niri
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
