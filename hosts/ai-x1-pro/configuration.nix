{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    ../../modules/core/nixos-base.nix
    ../../modules/desktop/nixos-desktop.nix
    ../../modules/core/company-ca.nix
    ../../modules/core/sops.nix
    ../../modules/services/wireguard-client.nix
    ../../modules/hardware/printing.nix
  ];

  networking.hostName = "ai-x1-pro";
  networking.networkmanager.enable = true;
  # Allow asymmetric return paths when Wi-Fi, Ethernet, or WireGuard overlap.
  networking.firewall.checkReversePath = "loose";

  # --- [절전 기능 비활성화] ---
  # 원격 접속 안정성을 위해 모든 형태의 절전을 끕니다.
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  services.displayManager.gdm.autoSuspend = false;

  # --- [NVIDIA eGPU (Oculink) 설정] ---
  # 이 카드에는 USB-C 포트가 없으며 c5:00.3의 UCSI 초기화가 시간 초과됩니다.
  # GPU USB-C 제어용 드라이버만 차단합니다. NVIDIA 화면 출력·OCuLink PCIe는 유지합니다.
  boot.blacklistedKernelModules = [ "i2c_nvidia_gpu" ];

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
