{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    niri
  ];

  # 텍스트 대신 실제 파일을 연결(source)합니다.
  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;
  xdg.configFile."niri/binds.kdl".source = ./niri/binds.kdl;
}
