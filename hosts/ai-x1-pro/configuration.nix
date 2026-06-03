{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    ../../modules/core/nixos-base.nix
    ../../modules/core/sops.nix
    ../../modules/services/wireguard-client.nix
    ../../modules/services/local-ai.nix
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
}
