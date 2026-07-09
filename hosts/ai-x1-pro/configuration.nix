{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    ../../modules/core/nixos-base.nix
    ../../modules/core/sops.nix
    ../../modules/services/wireguard-client.nix
    ../../modules/services/local-ai.nix
    ../../modules/hardware/printing.nix
  ];

  networking.hostName = "ai-x1-pro";
  networking.networkmanager.enable = true;

  # --- [GPU Memory Optimization] ---
  # 96GB RAM 중 64GB를 GPU가 활용할 수 있도록 설정 (GTT size)
  boot.kernelParams = [ "amdgpu.gttsize=65536" ];

  # --- [절전 기능 비활성화] ---
  # 원격 접속 안정성을 위해 모든 형태의 절전을 끕니다.
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  services.displayManager.gdm.autoSuspend = false;

  # --- [NVIDIA eGPU (Oculink) 설정] ---
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false; # Turing (RTX 2070 Super) 아키텍처는 proprietary 드라이버가 안정적임
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # Bus ID: 16진수 값을 10진수로 환산하여 설정
      # lspci: 
      # c7:00.0 Display controller: AMD/ATI [Radeon 880M / 890M] -> hex c7 = dec 199
      # c5:00.0 VGA compatible controller: NVIDIA RTX 2070 SUPER -> hex c5 = dec 197
      amdgpuBusId = "PCI:199:0:0";
      nvidiaBusId = "PCI:197:0:0";
    };
  };

  # Docker/Podman 컨테이너 내부 GPU 가속 지원
  hardware.nvidia-container-toolkit.enable = true;

  # GPU 모니터링 및 개발용 유틸리티 (AMD + NVIDIA 동시 모니터링 가능)
  environment.systemPackages = with pkgs; [
    nvtopPackages.full
  ];
}
