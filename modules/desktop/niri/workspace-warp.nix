{ config, lib, pkgs, ... }:

let
  cfg = config.local.desktop.workspaceWarp;
  python = pkgs.python3.withPackages (ps: [ ps.pygobject3 ps.pycairo ps.pyopengl ps.numpy ps.pillow ]);
  workspaceWarp = pkgs.stdenvNoCC.mkDerivation {
    pname = "niri-workspace-warp";
    version = "1.0";
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.wrapGAppsHook4 pkgs.gobject-introspection ];
    buildInputs = [ pkgs.gtk4 pkgs.gtk4-layer-shell ];
    installPhase = ''
      mkdir -p $out/bin $out/share/niri-workspace-warp
      cp ${./workspace-warp.py} $out/share/niri-workspace-warp/main.py
      cp ${./workspace-warp.glsl} $out/share/niri-workspace-warp/workspace-warp.glsl
      cp ${./monitor-flash.py} $out/share/niri-workspace-warp/monitor_flash.py
      makeWrapper ${python}/bin/python3 $out/bin/niri-workspace-warp \
        --add-flags $out/share/niri-workspace-warp/main.py \
        --set GSK_RENDERER gl \
        --set PYOPENGL_PLATFORM egl \
        --prefix PATH : ${lib.makeBinPath [ pkgs.niri config.programs.noctalia.package ]} \
        --prefix LD_PRELOAD : ${pkgs.gtk4-layer-shell}/lib/libgtk4-layer-shell.so
    '';
  };
in
{
  options.local.desktop.workspaceWarp.enable = lib.mkEnableOption
    "Brief wallpaper deformation on Niri workspace transitions (Noctalia crop mode)";

  config = lib.mkIf cfg.enable {
    home.packages = [ workspaceWarp ];
    systemd.user.services.niri-workspace-warp = {
      Unit = {
        Description = "Directional wallpaper warp on Niri workspace transitions";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        ConditionEnvironment = "NIRI_SOCKET";
      };
      Service = {
        ExecStart = "${workspaceWarp}/bin/niri-workspace-warp";
        Restart = "on-failure";
        RestartSec = 2;
        Environment = [ "GDK_BACKEND=wayland" "GTK_A11Y=none" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
