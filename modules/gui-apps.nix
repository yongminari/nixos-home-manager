{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    google-chrome
    alacritty 
    ghostty
    xwayland-satellite # Wayland 상에서 X11 앱 보조용
  ];

  # Ghostty 설정
  xdg.configFile."ghostty/config".text = ''
    font-family = "Maple Mono NF"
    font-family = "D2Coding"
    font-size = 12
    command = ${pkgs.zsh}/bin/zsh
  '';
}
