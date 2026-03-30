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
    ./modules/theme.nix
    ./modules/rclone.nix
    ./modules/hyprlock.nix
    ./modules/hypridle.nix
  ];

  home.username = "yongminari";
  home.homeDirectory = "/home/yongminari";
  home.stateVersion = "25.11";
 
  home.packages = with pkgs; [
    fnm
    alacritty 
    ghostty
    google-chrome
    xwayland-satellite
    lolcat
    fastfetch
    htop
    lsb-release
    swaybg
    hyprlock
    hypridle
  ];

    # Starship SSH 설정 파일 연결
    xdg.configFile."starship-ssh.toml".source = ./modules/shell/starship-ssh.toml;

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
