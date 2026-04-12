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

    # SSH 접속 시 터미널 정보(terminfo)를 자동으로 원격지에 복사하여 글자 중복 입력 현상 해결
    shell-integration-features = ssh-terminfo
  '';
}
