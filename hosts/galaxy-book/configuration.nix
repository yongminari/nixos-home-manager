{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    ../../modules/core/nixos-base.nix
  ];

  networking.hostName = "galaxy-book";
  networking.networkmanager.enable = true;

  # 하드웨어 최적화 활성화
  hardware.optimizations.galaxy-book.enable = true;

  # WireGuard VPN 설정
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

  systemd.services.wireguard-wg0.wantedBy = pkgs.lib.mkForce [ ];
}
