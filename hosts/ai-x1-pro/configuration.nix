{ config, pkgs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix 
    ../../modules/core/nixos-base.nix
    ../../modules/core/sops.nix
    ../../modules/services/wireguard-client.nix
  ];

  networking.hostName = "ai-x1-pro";
  networking.networkmanager.enable = true;
}
