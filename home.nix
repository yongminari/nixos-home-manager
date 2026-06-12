{ config, pkgs, lib, inputs, osConfig, username, ... }:

{
  imports = [
    # [1. core] 필수 설정 및 CLI
    ./modules/core/system-utils.nix
    ./modules/core/theme.nix
    ./modules/core/fonts.nix
    ./modules/core/shell/utils.nix
    ./modules/core/shell/yazi.nix
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
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.11";
 
  # --- [Global Packages] ---
  home.packages = with pkgs; [
    libnotify        # 알림용
    fnm              # Node.js 버전 매니저
    google-cloud-sdk # Google Cloud SDK
  ];

  # --- [Global Session Variables] ---
  home.sessionVariables = lib.mkMerge [
    {
      NIXOS_OZONE_WL = "1"; # Wayland 호환성 (Chromium/Electron 등)
      TERMINAL = "ghostty"; # 기본 터미널 설정

      # [Qt & Wayland Stability]
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    }
    # NVIDIA 그래픽 드라이버가 활성화된 호스트에서만 주입 (NVIDIA 전용 설정)
    (lib.mkIf (lib.elem "nvidia" (osConfig.services.xserver.videoDrivers or [])) {
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      QSG_RHI_BACKEND = "opengl"; # Quickshell/Qt6 rendering fix for NVIDIA
    })
    (lib.mkIf osConfig.modules.core.vertexAI.enable {
      # [Gemini CLI & Vertex AI Settings]
      GOOGLE_CLOUD_PROJECT = "gemini-cli-vertex-ai-493207";
      GOOGLE_CLOUD_LOCATION = "global"; # 서울 리전
      GOOGLE_APPLICATION_CREDENTIALS = "${config.home.homeDirectory}/.config/gcloud/application_default_credentials.json";
      GOOGLE_GENAI_USE_VERTEXAI = "True";
    })
  ];

  # --- [Secret Configurations Symlinks] ---
  home.file = {
    # Vertex AI Credentials Template
    ".config/gcloud/application_default_credentials.json" = lib.mkIf osConfig.modules.core.vertexAI.enable {
      source = config.lib.file.mkOutOfStoreSymlink "/run/secrets/rendered/application_default_credentials.json";
    };

    # GitLab CLI Configuration Template
    ".config/glab-cli/config.yml".source = config.lib.file.mkOutOfStoreSymlink "/run/secrets/rendered/glab-config.yml";
  };

  # --- [Settings] ---
  fonts.fontconfig.enable = true;
  programs.home-manager.enable = true;

  home.shellAliases = {
    hms = "nh home switch"; 
    ns  = "nh os switch";  
  };
}
