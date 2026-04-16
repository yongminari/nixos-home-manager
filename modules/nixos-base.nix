{ config, pkgs, ... }:

{
  imports = [
    ./containers.nix # [New] Distrobox & Podman
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
    vim git curl wget net-tools
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
          caps esc
        )

        (defalias
          esc-en (multi esc C-S-A-f12)
        )

        (deflayer default
          lctl @esc-en
        )
      '';
    };
  };
  # --- [9. Systemd Timeout Optimization] ---
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "10s";
  };
}
