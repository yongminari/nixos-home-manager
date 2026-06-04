{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    ../../modules/core/nixos-base.nix
    ../../modules/core/sops.nix
  ];

  networking = {
    hostName = "nxtp-office-desktop";
    networkmanager.enable = true;
    
    # DNS 서버 추가
    nameservers = [ "8.8.8.8" "1.1.1.1" ];
    
    interfaces = {
      enp13s0 = {
        ipv4.addresses = [ { address = "192.168.0.2"; prefixLength = 24; } ];
      };
      enp6s0f3 = {
        ipv4.addresses = [ { address = "192.168.2.2"; prefixLength = 24; } ];
        # 1번 망으로 향하는 테스트 패킷을 2번 게이트웨이로 명시적 이정표 고정
        ipv4.routes = [
          { address = "192.168.1.0"; prefixLength = 24; via = "192.168.2.1"; }
        ];
      };
    };

    # 기가비트 유선 회사 망을 메인 디폴트 게이트웨이로 고정
    defaultGateway = {
      address = "192.168.0.1";
      interface = "enp13s0";
      metric = 100;
    };
  };

  # --- [1. NVIDIA 그래픽 드라이버 설정] ---
  services.xserver.videoDrivers = [ "nvidia" ];

  # Google Vertex AI 기능 비활성화
  modules.core.vertexAI.enable = false;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # NVIDIA Container Toolkit (Podman/Docker GPU 지원)
  hardware.nvidia-container-toolkit.enable = true;

  # Wayland 안정성을 위한 커널 파라미터 추가
  boot.kernelParams = [ "nvidia-drm.fbdev=1" ];

  # --- [3. 절전 기능 비활성화] ---
  # 원격 접속 안정성을 위해 모든 형태의 절전을 끕니다.
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  services.displayManager.gdm.autoSuspend = false;

  # --- [4. 호스트 고유 패키지 설치] ---
  environment.systemPackages = with pkgs; [ 
    nvtopPackages.nvidia 
  ];
}
