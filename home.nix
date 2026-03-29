{ config, pkgs, ... }:

{
  imports = [
    ./modules/anyrun.nix
    ./modules/waybar.nix
    ./modules/niri.nix
    ./modules/shell/utils.nix
    ./modules/shell/welcome.nix
    ./modules/shell/bash.nix
    ./modules/shell/zsh.nix
    ./modules/shell/nushell.nix
    ./modules/shell/zellij.nix
  ];

  home.username = "yongminari";
  home.homeDirectory = "/home/yongminari";
  home.stateVersion = "25.11";
 
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    fnm
    alacritty 
    ghostty
    google-chrome                 # 크롬 브라우저 추가
    xwayland-satellite
    adwaita-icon-theme
    lolcat                        # 환영 메시지 무지개 색상용
    wl-clipboard                  # Wayland 클립보드 도구 (wl-copy, wl-paste)
  ];

    # Starship SSH 설정 파일 연결
    xdg.configFile."starship-ssh.toml".source = ./modules/shell/starship-ssh.toml;

    # 마우스 커서 설정 (niri 커서 경고 해결 및 일관성)
    home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
    };

    fonts.fontconfig.enable = true;

    xdg.configFile."ghostty/config".text = ''
    font-family = "Maple Mono NF"
    font-family = "D2Coding"
    font-size = 12
    command = ${pkgs.zsh}/bin/zsh
    '';

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    EDITOR = "vim";
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "yongminari";
        email = "easyid21c@gmail.com";
      };
      init.defaultBranch = "main";
    };
  };

  programs.home-manager.enable = true;
}
