{ config, pkgs, inputs, ... }:

{
  imports = [
    # [1. 시스템 관련]
    ./modules/noctalia.nix
    ./modules/system-utils.nix
    ./modules/theme.nix
    ./modules/rclone.nix
    
    # [2. 데스크탑 & GUI]
    ./modules/niri.nix
    ./modules/hyprlock.nix
    ./modules/hypridle.nix
    ./modules/gui-apps.nix
    ./modules/ghostty.nix
    
    # [3. 개발 도구]
    ./modules/git.nix
    ./modules/dev-tools.nix
    ./modules/neovim.nix
    ./modules/ros.nix
    
    # [4. 쉘 & CLI 터미널]
    ./modules/shell/utils.nix
    ./modules/shell/welcome.nix
    ./modules/shell/bash.nix
    ./modules/shell/zsh.nix
    ./modules/shell/nushell.nix
    ./modules/shell/zellij.nix
  ];

  # --- [User Information] ---
  home.username = "yongminari";
  home.homeDirectory = "/home/yongminari";
  home.stateVersion = "25.11";
 
  # --- [Global Packages] ---
  home.packages = with pkgs; [
    home-manager
    libnotify        # 알림용
    fnm              # Node.js 버전 매니저
    google-cloud-sdk # Google Cloud SDK
  ];

  # --- [Global Session Variables] ---
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Wayland 호환성 (Chromium/Electron 등)
    TERMINAL = "ghostty"; # 기본 터미널 설정

    # [Gemini CLI Settings]
    GOOGLE_CLOUD_PROJECT = "gemini-cli-vertex-ai-493207";
    GOOGLE_CLOUD_LOCATION = "global"; # 서울 리전
    GOOGLE_APPLICATION_CREDENTIALS = "/home/yongminari/.config/gcloud/application_default_credentials.json";
    GOOGLE_GENAI_USE_VERTEXAI = "True";
  };

  # --- [Settings] ---
  fonts.fontconfig.enable = true;
  programs.home-manager.enable = true;
}
