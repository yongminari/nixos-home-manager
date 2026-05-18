{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    ../../modules/core/nixos-base.nix
    ../../modules/core/sops.nix
  ];

  networking.hostName = "nxtp-office-desktop";
  networking.networkmanager.enable = true;

  # --- [1. NVIDIA 그래픽 드라이버 설정] ---
  services.xserver.videoDrivers = [ "nvidia" ];

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

  # --- [2. 호스트 고유 패키지 설치] ---
  environment.systemPackages = with pkgs; [ 
    nvtopPackages.nvidia 
  ];
}
