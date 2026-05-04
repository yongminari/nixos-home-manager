{ config, pkgs, osConfig, ... }:

let
  hostname = osConfig.networking.hostName or "";
  # 호스트별 스케일 정의
  scale = "1.0";
  
  # 기존 설정 파일 내용 읽기
  baseConfig = builtins.readFile ./niri/config.kdl;
in
{
  home.packages = with pkgs; [
    niri
    xwayland-satellite # XWayland 지원
  ];

  systemd.user.targets.niri-session = {
    Unit = {
      Description = "niri compositor session";
      Documentation = [ "man:systemd.special(7)" ];
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
    };
  };

  # 키보드 고정 설정 (Nix 관리)
  xdg.configFile."niri/keyboard.kdl".text = ''
    keyboard {
        xkb {
            layout "us"
        }
        repeat-delay 400
        repeat-rate 40
    }
  '';

  # 터치패드 설정 디렉토리 보장
  systemd.user.tmpfiles.rules = [
    "d %h/.config/niri 0755 - - -"
  ];

  # 터치패드 토글 스크립트
  xdg.configFile."niri/toggle-touchpad.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      INPUT_CONFIG="$HOME/.config/niri/input.kdl"
      KEYBOARD_CONFIG="$HOME/.config/niri/keyboard.kdl"
      
      # 키보드 설정 읽기 (파일이 없으면 기본값 사용)
      if [ -f "$KEYBOARD_CONFIG" ]; then
          KBD_SETTINGS=$(cat "$KEYBOARD_CONFIG")
      else
          KBD_SETTINGS="    keyboard { xkb { layout \"us\" }; repeat-delay 400; repeat-rate 40; }"
      fi

      if grep -q "off" "$INPUT_CONFIG"; then
          # 활성화 상태로 생성
          printf "input {\n%s\n    touchpad {\n        tap\n        natural-scroll\n    }\n}\n" "$KBD_SETTINGS" > "$INPUT_CONFIG"
          notify-send -t 1500 -i input-touchpad "Touchpad" "Enabled"
      else
          # 비활성화 상태로 생성
          printf "input {\n%s\n    touchpad {\n        off\n    }\n}\n" "$KBD_SETTINGS" > "$INPUT_CONFIG"
          notify-send -t 1500 -i input-touchpad "Touchpad" "Disabled"
      fi
      
      niri msg action load-config-file
    '';
  };

  # 설정을 text로 생성하여 스케일 값을 주입
  xdg.configFile."niri/config.kdl".text = ''
    // 호스트별 자동 생성된 출력 설정
    output "eDP-1" {
        scale ${scale}
    }

    ${baseConfig}
    
    // 통합 입력 설정 포함
    include "input.kdl"
  '';

  xdg.configFile."niri/binds.kdl".source = ./niri/binds.kdl;
}
