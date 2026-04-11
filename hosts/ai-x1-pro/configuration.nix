{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    ../../modules/nixos-base.nix
  ];

  # --- [1. Network & Identity] ---
  networking.hostName = "ai-x1-pro";
  networking.networkmanager.enable = true;

  # WireGuard VPN 설정 (ai-x1-pro 전용)
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

  # 기기 전용 패키지
  environment.systemPackages = with pkgs; [ 
    wireguard-tools 
  ];
}
