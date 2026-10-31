{ lib, ... }:

{
  options.local.desktop = {
    adaptiveGenieClose = lib.mkEnableOption "Predict the next focus direction for the Niri close shortcut";
    windowAnimation = lib.mkOption {
      type = lib.types.enum [ "smoke" "genie" ];
      default = "smoke";
      description = "Niri window opening and closing shader.";
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
      default = [];
      description = "Host-specific Chrome command-line arguments.";
    };
  };
}
