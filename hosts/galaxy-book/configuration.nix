{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    ../../modules/core/nixos-base.nix
    ../../modules/core/sops.nix
    ../../modules/services/wireguard-client.nix
    ../../modules/hardware/printing.nix
    ../../modules/hardware/samsung-galaxy-book.nix
  ];

  networking.hostName = "galaxy-book";
  networking.networkmanager.enable = true;

  # 삼성 갤럭시 북 전용 하드웨어 최적화 활성화
  hardware.samsung-galaxy-book.enable = true;

  # 이 장치의 배터리 충전을 90%로 제한
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="BAT1", TEST=="charge_control_end_threshold", ATTR{charge_control_end_threshold}!="90", ATTR{charge_control_end_threshold}="90"
  '';
}
