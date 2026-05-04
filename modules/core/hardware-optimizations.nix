{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardware.optimizations;
in {
  options.hardware.optimizations = {
    galaxy-book = {
      enable = mkEnableOption "Galaxy Book hardware optimizations";
    };
  };

  config = mkIf cfg.galaxy-book.enable {
    # --- [Hardware Optimization] ---
    boot.kernelParams = [ 
      "snd_intel_dspcfg.dsp_driver=1"
      "snd_hda_intel.model=alc298-samsung-amp-v2-4-amps"
      "i915.enable_dpcd_backlight=3"
    ];

    services.thermald.enable = true;
    services.auto-cpufreq.enable = true;
    services.power-profiles-daemon.enable = false;

    services.udev.packages = [ pkgs.brightnessctl ];
    
    environment.systemPackages = with pkgs; [ 
      sof-firmware alsa-utils pavucontrol 
      brightnessctl
    ];
  };
}
