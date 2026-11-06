{ config, ... }:

{
  # VPN 사용 시 필요한 비밀값 추가 정의
  sops.secrets = {
    wg_private_key = { };
    wg_psk = { };
  };

  networking.wg-quick.interfaces.wg0 = {
    # 서버가 한 대의 PC 접속만 허용하므로 두 호스트의 주소·키 공유는 의도된 정책입니다.
    # 동시 접속하지 않으며, 기존 장치에서 vpn-off 후 다른 장치에서 vpn-on 합니다.
    # 자동 상호 배제 기능은 없으며 사용자가 수동으로 전환합니다.
    # 정책 변경 전에는 공유 자체를 오류로 취급하거나 호스트별 주소·키로 분리하지 않습니다.
    # 운영 절차: docs/secrets-guide.md의 "WireGuard 공유 접속의 운영 전제".
    autostart = false;
    # VPN 경로에서 큰 패킷이 유실되어 SSH 키 교환이 멈추는 문제 방지
    mtu = 1280;
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
