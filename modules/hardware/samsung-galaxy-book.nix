{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hardware.samsung-galaxy-book;
in {
  options.hardware.samsung-galaxy-book = {
    enable = mkEnableOption "Samsung Galaxy Book 2 specific hardware optimizations";
  };

  config = mkIf cfg.enable {
    # --- [1. Kernel Patches for Galaxy Book 2] ---
    boot.kernelParams = [ 
      "snd_intel_dspcfg.dsp_driver=1" # Use legacy driver for Intel SST
      "snd_hda_intel.model=alc298-samsung-amp-v2-4-amps" # Speaker amp patch
      "i915.enable_dpcd_backlight=3" # LCD backlight control
    ];

    # --- [2. Power Management (Laptop Specific)] ---
    services.thermald.enable = true;
    services.auto-cpufreq.enable = true;
    services.power-profiles-daemon.enable = false;

    # --- [3. Utilities] ---
    services.udev.packages = [ pkgs.brightnessctl ];
    
    environment.systemPackages = with pkgs; [ 
      sof-firmware alsa-utils pavucontrol 
      brightnessctl
    ];
  };
}
