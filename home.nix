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
    ./modules/git.nix
    ./modules/dev-tools.nix
    ./modules/neovim.nix
    ./modules/system-utils.nix
    ./modules/notifications.nix
  ];

  home.username = "yongminari";
  home.homeDirectory = "/home/yongminari";
  home.stateVersion = "25.11";
 
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    fnm
    alacritty 
    ghostty
    google-chrome
    xwayland-satellite
    adwaita-icon-theme
    lolcat
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
  };

  programs.home-manager.enable = true;
}
