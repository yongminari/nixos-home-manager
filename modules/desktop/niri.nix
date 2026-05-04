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

  # 터치패드 설정 디렉토리 보장
  systemd.user.tmpfiles.rules = [
    "d %h/.config/niri 0755 - - -"
  ];

  # 터치패드 토글 스크립트 (갤럭시 북 전용)
  xdg.configFile."niri/toggle-touchpad.sh" = pkgs.lib.mkIf (hostname == "galaxy-book") {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      INPUT_CONFIG="$HOME/.config/niri/touchpad-control.kdl"

      if grep -q "off" "$INPUT_CONFIG" 2>/dev/null; then
          # 활성화 상태로 생성
          printf "input {\n    touchpad {\n        tap\n        natural-scroll\n    }\n}\n" > "$INPUT_CONFIG"
          notify-send -t 1500 -i input-touchpad "Touchpad" "Enabled"
      else
          # 비활성화 상태로 생성
          printf "input {\n    touchpad {\n        off\n    }\n}\n" > "$INPUT_CONFIG"
          notify-send -t 1500 -i input-touchpad "Touchpad" "Disabled"
      fi

      niri msg action load-config-file
    '';
  };

  # 설정을 text로 생성하여 스케일 값을 유입
  xdg.configFile."niri/config.kdl".text = ''
    // 호스트별 자동 생성된 출력 설정
    output "eDP-1" {
        scale ${scale}
    }

    ${baseConfig}

    // 기본 입력 설정 (모든 기기 공통)
    input {
        keyboard {
            xkb {
                layout "us"
            }
            repeat-delay 400
            repeat-rate 40
        }
    }

    ${pkgs.lib.optionalString (hostname == "galaxy-book") ''
    // 갤럭시 북 전용 입력 설정 (터치패드)
    // 주의: include는 최상위 레벨에서만 작동하므로 input 블록 밖에 위치해야 함
    include "touchpad-control.kdl"
    ''}
  '';


  xdg.configFile."niri/binds.kdl".source = ./niri/binds.kdl;
}
