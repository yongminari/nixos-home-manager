{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    ../../modules/nixos-base.nix
  ];

  # --- [1. Network & Identity] ---
  networking.hostName = "galaxy-book";
  networking.networkmanager.enable = true;

  # WireGuard VPN 설정 (galaxy-book)
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.0.151.9/24" ];
    privateKeyFile = "/etc/wireguard/wg0.key";
    peers = [
      {
        publicKey = "xKId6dwAyUbnDlfgS6cx0/cshyq9H/uKLmE8uYAsCiI=";
        presharedKeyFile = "/etc/wireguard/wg0.psk";
        allowedIPs = [ "192.168.0.0/24" ];
        endpoint = "58.121.116.136:55536";
        persistentKeepalive = 25;
      }
    ];
  };

  # 부팅 시 WireGuard 자동 시작 방지
  systemd.services.wireguard-wg0.wantedBy = pkgs.lib.mkForce [ ];

  # --- [2. Hardware Optimization] ---
  # 갤럭시 북2 사운드 및 백라이트 해결을 위한 커널 파라미터
  boot.kernelParams = [ 
    "snd_intel_dspcfg.dsp_driver=1" # Intel SST 대신 레거시 드라이버 사용
    "snd_hda_intel.model=alc298-samsung-amp-v2-4-amps" # 스피커 앰프 패치
    "i915.enable_dpcd_backlight=3" # LCD 백라이트 제어 활성화
  ];

  # --- [3. Power Management] ---
  services.thermald.enable = true;
  services.auto-cpufreq.enable = true;
  services.power-profiles-daemon.enable = false;

  # --- [4. Specific Services & Packages] ---
  services.udev.packages = [ pkgs.brightnessctl ];
  
  environment.systemPackages = with pkgs; [ 
    sof-firmware alsa-utils pavucontrol 
    brightnessctl
    wireguard-tools
  ];
}
