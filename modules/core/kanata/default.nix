{ pkgs, ... }:

{
  services.kanata = {
    enable = true; # Set to false to disable Kanata
    package = pkgs.kanata-with-cmd;
    keyboards.default = {
      devices = [ ]; 
      extraDefCfg = "process-unmapped-keys yes";
      config = builtins.readFile ./kanata.kbd;
    };
  };

  # Preparation for QMK/Vial
  hardware.keyboard.qmk.enable = true;
  services.udev.packages = [ pkgs.vial ];
}
