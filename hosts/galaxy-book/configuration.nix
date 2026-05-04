{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    ../../modules/core/nixos-base.nix
  ];

  networking.hostName = "galaxy-book";
  networking.networkmanager.enable = true;

  # 삼성 갤럭시 북 전용 하드웨어 최적화 활성화
  hardware.samsung-galaxy-book.enable = true;

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

  # 부팅 시 자동 시작 방지 (수동 시작: sudo systemctl start wireguard-wg0)
  systemd.services.wireguard-wg0.wantedBy = pkgs.lib.mkForce [ ];

  environment.systemPackages = with pkgs; [ 
    wireguard-tools 
  ];
}
