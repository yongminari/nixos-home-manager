{ config, pkgs, ... }:

{
  imports = [
    ./containers.nix
    ../hardware/samsung-galaxy-book.nix
  ];

  # --- [1. Boot & System Engine] ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "uinput" ];

  # --- [2. Locale & Timezone] ---
  time.timeZone = "Asia/Seoul";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ko_KR.UTF-8"; LC_IDENTIFICATION = "ko_KR.UTF-8";
    LC_MEASUREMENT = "ko_KR.UTF-8"; LC_MONETARY = "ko_KR.UTF-8";
    LC_NAME = "ko_KR.UTF-8"; LC_NUMERIC = "ko_KR.UTF-8";
    LC_PAPER = "ko_KR.UTF-8"; LC_TELEPHONE = "ko_KR.UTF-8";
    LC_TIME = "ko_KR.UTF-8";
  };

  # --- [3. Desktop Environment (GNOME & Niri)] ---
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

  # --- [4. User Accounts & Shell] ---
  programs.zsh.enable = true;
  users.users.yongminari = {
    isNormalUser = true;
    description = "yongminari";
    extraGroups = [ "networkmanager" "wheel" "video" "input" "uinput" "audio" ];
    shell = pkgs.zsh; 
  };

  # --- [5. Input Method & Fonts] ---
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-hangul fcitx5-gtk fcitx5-lua ];
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


  # --- [6. System Services & Utilities] ---
  services.upower.enable = true;
  hardware.bluetooth.enable = true;
  hardware.enableAllFirmware = true; 
  hardware.enableRedistributableFirmware = true; 
  services.printing.enable = true;
  security.rtkit.enable = true;
  security.pki.certificates = [
    ''
    -----BEGIN CERTIFICATE-----
    MIIBsDCCAVagAwIBAgIRAMHBbZWmymbmLKvyFpepQ6gwCgYIKoZIzj0EAwIwNjEV
    MBMGA1UEChMMbnh0cC1jYS1zdGVwMR0wGwYDVQQDExRueHRwLWNhLXN0ZXAgUm9v
    dCBDQTAeFw0yNTExMTMxMjMyNTBaFw0zNTExMTExMjMyNTBaMDYxFTATBgNVBAoT
    DG54dHAtY2Etc3RlcDEdMBsGA1UEAxMUbnh0cC1jYS1zdGVwIFJvb3QgQ0EwWTAT
    BgcqhkjOPQIBBggqhkjOPQMBBwNCAAStj0NKsFMfj+atQd41Wvdrsuc+vxCAT/bH
    f9V0N2dR9b0z6BtjEqin0LDzRyHsqPf2cvBNDoLJI+13IpaL0qJ9o0UwQzAOBgNV
    HQ8BAf8EBAMCAQYwEgYDVR0TAQH/BAgwBgEB/wIBATAdBgNVHQ4EFgQUVsO9CbpS
    JP1SLOVGEB6cqkqFqiEwCgYIKoZIzj0EAwIDSAAwRQIhAJC5a/pTRehwdINCaObt
    pxedbxX6uj84Xk8uz5Pns2S1AiAmwIANAxCLpTyOnH921D55ZKPbfLD916YUL1um
    lvGXTw==
    -----END CERTIFICATE-----
    ''
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  environment.systemPackages = with pkgs; [ 
    vim git curl wget net-tools wireguard-tools
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc zlib fuse3 icu nss openssl curl expat
  ];

  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="uinput", MODE="0660", OPTIONS+="static_node=uinput"
    KERNEL=="event*", NAME="input/%k", MODE="0660", GROUP="input"
  '';
  users.groups.uinput = {};
  users.groups.input = {};

  # --- [7. System Policy] ---
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.settings.trusted-users = [ "root" "yongminari" ];
  system.stateVersion = "25.11";

  # --- [8. Keyboard Remapping (Kanata)] ---
  services.kanata = {
    enable = true;
    package = pkgs.kanata-with-cmd;
    keyboards.default = {
      devices = [ ]; 
      extraDefCfg = "process-unmapped-keys yes";
      config = ''
        (defsrc
          caps
          q w e r t y u i o p
          a s d f g h j k l ; '
          z x c v b n m , . /
          spc lalt ralt
        )

        (defalias
          ;; --- [Layer Toggles] ---
          v-l (tap-hold 250 250 v (layer-toggle nav))
          n-l (tap-hold 250 250 n (layer-toggle nav))
          z-l (tap-hold 250 250 z (layer-toggle num))
          x-l (tap-hold 250 250 x (layer-toggle func))
          /-l (tap-hold-press 250 250 / (layer-toggle sym))

          ;; --- [Home Row Mods (GACS)] ---
          a-m (tap-hold 250 250 a lmet)
          s-a (tap-hold 250 250 s lalt)
          d-c (tap-hold 250 250 d lctl)
          f-s (tap-hold 250 250 f lsft)

          j-s (tap-hold 250 250 j rsft)
          k-c (tap-hold 250 250 k rctl)
          l-a (tap-hold 250 250 l ralt)
          ;-m (tap-hold 250 250 ; rmet)

          ;; --- [Special Aliases] ---
          ;; CapsLock position -> Ctrl / Esc.
          esc-en (tap-hold-press 250 250 (multi esc C-S-A-f12) lctl)
          
          ;; Layer Switches for Toggle
          tog-raw (layer-switch raw)
          tog-def (layer-switch default)

          ;; Mouse Movements & Scroll
          m-u (movemouse-up 4 1)
          m-l (movemouse-left 4 1)
          m-d (movemouse-down 4 1)
          m-r (movemouse-right 4 1)
          sc-u (mwheel-up 50 120)
          sc-d (mwheel-down 50 120)

          ;; Essential Alias for problem characters
          dqt S-'
        )

        (deflayer default
          @esc-en
          q w e r t y u i o p
          @a-m @s-a @d-c @f-s g h @j-s @k-c @l-a @;-m '
          @z-l @x-l c @v-l b @n-l m , . @/-l
          spc lalt ralt
        )

        (deflayer nav
          @tog-raw
          mlft @m-u mrgt mmid _ home pgup pgdn end _
          @m-l @m-d @m-r _ @sc-u left down up rght _ _
          _ _ @sc-d _ _ _ bspc del _ _
          _ _ _
        )

        (deflayer num
          _
          _ _ _ _ _ / 7 8 9 -
          _ _ _ _ _ S-8 4 5 6 S-= _
          _ _ _ _ _ 0 1 2 3 .
          _ _ _
        )

        (deflayer func
          _
          _ _ _ _ _ f12 f7 f8 f9 _
          _ _ _ _ _ f11 f4 f5 f6 _ _
          _ _ _ _ _ f10 f1 f2 f3 _
          _ _ _
        )

        (deflayer sym
          _
          S-1 S-2 S-3 S-4 S-5 _ _ _ _ _
          S-6 S-7 S-8 - = _ _ _ _ _ _
          S-` S-- S-= S-\ \ _ _ _ _ _
          _ _ _
        )

        (deflayer raw
          @tog-def ;; In RAW, same key toggles back to Default
          q w e r t y u i o p
          a s d f g h j k l ; '
          z x c v b n m , . /
          spc lalt ralt
        )
      '';
    };
  };
  # --- [9. Systemd Timeout Optimization] ---
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
  };
}
