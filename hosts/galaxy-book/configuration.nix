{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    ../../modules/core/nixos-base.nix
    ../../modules/core/sops.nix
    ../../modules/services/wireguard-client.nix
  ];

  networking.hostName = "galaxy-book";
  networking.networkmanager.enable = true;

  # 삼성 갤럭시 북 전용 하드웨어 최적화 활성화
  hardware.samsung-galaxy-book.enable = true;
}
