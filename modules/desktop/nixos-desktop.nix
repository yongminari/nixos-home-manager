{ pkgs, ... }:

{
  # --- [1. Desktop Environment (GNOME & Niri)] ---
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver.xkb = { layout = "us"; variant = ""; };

  environment.gnome.excludePackages = (with pkgs; [
    firefox gnome-tour gnome-maps gnome-weather
  ]);

  programs.niri.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = "*";
  };

  # --- [2. Input Method & Fonts] ---
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [ fcitx5-hangul fcitx5-gtk fcitx5-lua ];
      waylandFrontend = true;

      # 모든 호스트에 동일한 영문/한글 두벌식 기본값을 제공합니다.
      settings = {
        inputMethod = {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "hangul";
          };
          "Groups/0/Items/0".Name = "keyboard-us";
          "Groups/0/Items/1".Name = "hangul";
          GroupOrder."0" = "Default";
        };
        globalOptions = {
          "Hotkey/TriggerKeys" = {
            "0" = "Shift+space";
            "1" = "Zenkaku_Hankaku";
          };
          Behavior.ActiveByDefault = false;
        };
        addons.hangul.globalSection.Keyboard = "Dubeolsik";
      };
    };
  };

  fonts.packages = with pkgs; [ maple-mono.NF d2coding ];
  fonts.fontconfig = {
    enable = true;
    antialias = true;
    hinting = {
      enable = true;
      style = "full"; # 힌팅 강도를 최대로 설정하여 번짐 방지
    };
    subpixel = {
      rgba = "rgb";
      lcdfilter = "default";
    };
    defaultFonts = {
      monospace = [ "Maple Mono NF" "D2Coding" ];
      sansSerif = [ "Maple Mono NF" "D2Coding" ];
      serif = [ "Maple Mono NF" "D2Coding" ];
    };
  };

  # --- [3. Desktop Services] ---
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.upower.enable = true;
  hardware.bluetooth.enable = true;
  services.printing.enable = true;
  security.rtkit.enable = true;
}
