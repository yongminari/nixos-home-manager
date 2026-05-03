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

  # 설정을 text로 생성하여 스케일 값을 주입
  xdg.configFile."niri/config.kdl".text = ''
    // 호스트별 자동 생성된 출력 설정
    output "eDP-1" {
        scale ${scale}
    }

    ${baseConfig}
  '';

  xdg.configFile."niri/binds.kdl".source = ./niri/binds.kdl;
}
