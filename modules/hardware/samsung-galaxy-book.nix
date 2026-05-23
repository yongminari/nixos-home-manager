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
      mobile-broadband-provider-info
    ];

    # --- [4. Cellular & Modem] ---
    networking.modemmanager.enable = true;

    networking.networkmanager.ensureProfiles.profiles = {
      "KT LTE" = {
        connection = {
          id = "KT LTE";
          uuid = "bec8eef6-8276-4564-9161-ae2e80a829e0";
          type = "gsm";
          interface-name = "wwan0mbim0";
          autoconnect = true;
        };
        gsm = {
          apn = "lte.ktfwing.com";
          auto-config = false;
        };
        ipv4 = {
          method = "auto";
          route-metric = 100;
        };
        ipv6 = {
          method = "auto";
        };
      };
    };
  };
}
