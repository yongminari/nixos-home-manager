{ pkgs, lib, username, ... }:

{
  imports = [
    ./containers.nix
    ./dbus.nix
    ../services/tailscale.nix
  ];

  # --- [1. Boot & System Engine] ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  # --- [3. User Accounts & Shell] ---
  programs.zsh.enable = true;
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    # Niri uses logind session access; do not grant persistent raw input access.
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    shell = pkgs.zsh; 
  };

  # nh 4.4.2 invokes sudo env USER=... for local activation and clean all.
  # Keep this in sync with NH_PRESERVE_ENV in system-utils.nix. Do not allow
  # arbitrary env arguments: they could execute unrelated commands as root.
  # Applying user-built NixOS configurations still grants full system control.
  security.sudo.extraRules = [
    {
      users = [ username ];
      runAs = "root";
      commands = [
        {
          command = "${pkgs.coreutils}/bin/env ^(USER=${username} |NH_FLAKE=/home/${username}/nixos-home-manager |NH_PRESERVE_ENV=0 )+/nix/store/[a-z0-9]{32}-nixos-system-[^/ ]+/bin/switch-to-configuration (test|boot)$";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.coreutils}/bin/env ^(USER=${username} |NH_FLAKE=/home/${username}/nixos-home-manager |NH_PRESERVE_ENV=0 )+nix build --no-link --profile /nix/var/nix/profiles/system /nix/store/[a-z0-9]{32}-nixos-system-[^/ ]+$";
          options = [ "NOPASSWD" ];
        }
        {
          # clean all re-executes this exact nh binary as root; allow its flags,
          # but not other nh subcommands or arbitrary executables.
          command = "${pkgs.coreutils}/bin/env ^(USER=${username} |NH_FLAKE=/home/${username}/nixos-home-manager |NH_PRESERVE_ENV=0 )+${lib.escapeRegex "${pkgs.nh-unwrapped}/bin/nh"} clean all( .*)?$";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # --- [4. System Services & Utilities] ---
  hardware.enableAllFirmware = true; 
  hardware.enableRedistributableFirmware = true; 

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      # 키 접속은 모든 접속 장치에서 확인했으며 개인키는 각 장치에 보관합니다.
      # 새 장치의 공개키 등록을 위해 비밀번호 로그인도 의도적으로 유지합니다.
      PasswordAuthentication = true;
    };
  };

  environment.systemPackages = with pkgs; [ 
    vim git curl wget wireguard-tools
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc zlib fuse3 icu nss openssl curl expat
  ];

  # --- [5. System Policy] ---
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  # 개인 관리 계정의 Nix 작업 편의를 위해 관리자 수준의 신뢰 권한을 유지합니다.
  # 사용자 결정: 현재 방식으로 사용하고 보안 요구가 바뀌면 sudo 정책과 함께 재검토합니다.
  nix.settings.trusted-users = [ "root" username ];
  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://noctalia.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
  ];
  nix.settings.auto-optimise-store = true; # 중복 파일 자동 하드링크 최적화
  nix.gc = {
    automatic = true;
    dates = "weekly"; # 매주 한 번씩 자동으로 청소합니다.
    options = "--delete-generations +3";
  };
  system.stateVersion = "26.11";

  # --- [6. QMK Keyboard Firmware] ---
  # Firmware flashing uses QMK USB/hidraw rules, not input/uinput membership.
  hardware.keyboard.qmk.enable = true;
}
