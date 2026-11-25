{ config, lib, pkgs, ... }:

{
  home.packages = lib.mkIf config.local.desktop.adaptiveGenieClose [
    (pkgs.writeShellApplication {
      name = "niri-adaptive-close";
      runtimeInputs = [ pkgs.niri pkgs.python3 ];
      text = ''
        exec python3 ${./adaptive-close.py} "$@"
      '';
    })
  ];
}
