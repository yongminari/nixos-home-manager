{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # --- [1. Boot & System Engine] ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "uinput" ];

  # --- [2. Network & Locale] ---
  networking.hostName = "galaxy-book";
  networking.networkmanager.enable = true;
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
    extraGroups = [ "networkmanager" "wheel" "video" "input" "uinput" ];
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
  services.printing.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true; alsa.enable = true; alsa.support32Bit = true; pulse.enable = true;
  };

  # OpenSSH server 추가
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true; # 필요에 따라 SSH 키 인증만 허용하도록 바꿀 수 있습니다.
    };
  };

  environment.systemPackages = with pkgs; [ vim git curl wget ];

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
  system.stateVersion = "25.11";

  # --- [8. Power Management] ---
  services.thermald.enable = true;
  services.auto-cpufreq.enable = true;
  # auto-cpufreq와 충돌하는 기본 전원 프로필 서비스 비활성화
  services.power-profiles-daemon.enable = false;
}
