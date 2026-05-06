{ config, pkgs, inputs, ... }:

{
  imports = [
    (if builtins.pathExists ./local.nix then ./local.nix else {})

    # [1. core] 필수 설정 및 CLI
    ./modules/core/system-utils.nix
    ./modules/core/theme.nix
    ./modules/core/fonts.nix
    ./modules/core/shell/utils.nix
    ./modules/core/shell/welcome.nix
    ./modules/core/shell/bash.nix
    ./modules/core/shell/zsh.nix
    ./modules/core/shell/nushell.nix
    ./modules/core/shell/zellij.nix
    
    # [2. dev] 개발 환경
    ./modules/dev/git.nix
    ./modules/dev/dev-tools.nix
    ./modules/dev/neovim.nix
    ./modules/dev/ros.nix
    ./modules/dev/containers.nix

    # [3. desktop] UI 및 데스크탑 앱
    ./modules/desktop/niri
    ./modules/desktop/hyprlock.nix
    ./modules/desktop/hypridle.nix
    ./modules/desktop/gui-apps.nix
    ./modules/desktop/ghostty.nix
    ./modules/desktop/swappy.nix

    # [4. services] 백그라운드 서비스
    ./modules/services/noctalia.nix
    ./modules/services/rclone.nix
  ];

  # --- [User Information] ---
  home.username = "yongminari";
  home.homeDirectory = "/home/yongminari";
  home.stateVersion = "25.11";
 
  # --- [Global Packages] ---
  home.packages = with pkgs; [
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

  home.shellAliases = {
    hms = "nh home switch"; 
    ns  = "nh os switch";  
  };
}
