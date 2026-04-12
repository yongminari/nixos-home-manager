{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    niri
    swaybg # 배경화면용 (필요시)
    xwayland-satellite # XWayland 지원 (필요시)
  ];

  # Niri 환경 변수를 systemd에 공유하여 hypridle 등이 niri socket에 접근할 수 있게 함
  systemd.user.targets.niri-session = {
    Unit = {
      Description = "niri compositor session";
      Documentation = [ "man:systemd.special(7)" ];
      BindsTo = [ "graphical-session.target" ];
      Wants = [ "graphical-session-pre.target" ];
      After = [ "graphical-session-pre.target" ];
    };
  };

  # 텍스트 대신 실제 파일을 연결(source)합니다.
  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;
  xdg.configFile."niri/binds.kdl".source = ./niri/binds.kdl;
}
