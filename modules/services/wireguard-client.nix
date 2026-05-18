{ config, ... }:

{
  # VPN 사용 시 필요한 비밀값 추가 정의
  sops.secrets = {
    wg_private_key = { };
    wg_psk = { };
  };

  networking.wg-quick.interfaces.wg0 = {
    autostart = false;
    address = [ "10.0.151.9/24" ];
    privateKeyFile = config.sops.secrets.wg_private_key.path;
    
    peers = [
      {
        publicKey = "xKId6dwAyUbnDlfgS6cx0/cshyq9H/uKLmE8uYAsCiI=";
        presharedKeyFile = config.sops.secrets.wg_psk.path;
        allowedIPs = [ "192.168.0.0/24" ];
        endpoint = "58.121.116.136:55536";
        persistentKeepalive = 25;
      }
    ];
  };
}
