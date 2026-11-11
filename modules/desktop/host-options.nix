{ lib, ... }:

{
  options.local.desktop = {
    monitorIdleRefresh = {
      blur = lib.mkEnableOption "Show a subtle blur while preparing idle monitor power-off";
      enable = lib.mkEnableOption "Lower refresh rate before automatic monitor power-off";
      output = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Niri output name or make/model/serial selector for the idle refresh workaround.";
      };
    };
    monitorOffTimeout = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = 900;
      description = "Idle time in seconds before powering off monitors; null disables automatic monitor power-off.";
    };
    adaptiveGenieClose = lib.mkEnableOption "Predict the next focus direction for the Niri close shortcut";
    windowAnimation = lib.mkOption {
      type = lib.types.enum [ "smoke" "genie" "black-hole" "ink" "glacier" "glass-pressure" ];
      default = "smoke";
      description = "Niri window closing shader (windows open with the dust-explosion shader).";
    };
    isLaptop = lib.mkOption {
      type = lib.types.bool;
      description = "Whether this host uses laptop input and idle behavior.";
    };
    scale = lib.mkOption {
      type = lib.types.str;
      default = "1.0";
      description = "Default Niri output scale.";
    };
    outputs = lib.mkOption {
      type = lib.types.nullOr (lib.types.submodule {
        options = {
          left = lib.mkOption { type = lib.types.str; };
          right = lib.mkOption { type = lib.types.str; };
        };
      });
      default = null;
      description = "Output selectors for the left/right monitor toggles.";
    };
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Host-specific Niri output configuration.";
    };
    chromeArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "--ozone-platform=x11" ];
      description = "Chrome command-line arguments; defaults to XWayland on all hosts.";
    };
  };
}
