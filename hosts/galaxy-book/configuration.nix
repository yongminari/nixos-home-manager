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

  # Sops 설정
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/home/yongminari/.config/sops/age/keys.txt";
    secrets = {
      wg_private_key = { };
      wg_psk = { };
      vertex_ai_key = {
        # 원하는 경로에 자동으로 파일을 생성합니다.
        path = "/home/yongminari/.config/gcloud/application_default_credentials.json";
        owner = "yongminari";
      };
    };
  };

  # WireGuard 설정 (wg-quick 방식)
  networking.wg-quick.interfaces.wg0 = {
    autostart = false; # 부팅 시 자동 시작 방지 (토글 모드)
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

  environment.systemPackages = with pkgs; [ 
    wireguard-tools 
  ];
}
