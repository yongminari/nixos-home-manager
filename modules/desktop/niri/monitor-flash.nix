{ config, lib, pkgs, ... }:

let
  cfg = config.local.desktop.monitorFlash;
  python = pkgs.python3.withPackages (ps: [ ps.pygobject3 ps.pycairo ps.pyopengl ps.numpy ]);
  monitorFlash = pkgs.stdenvNoCC.mkDerivation {
    pname = "niri-monitor-flash";
    version = "2.0";
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.wrapGAppsHook4 pkgs.gobject-introspection ];
    buildInputs = [ pkgs.gtk4 pkgs.gtk4-layer-shell ];
    installPhase = ''
      mkdir -p $out/bin $out/share/niri-monitor-flash
      cp ${./monitor-flash.py} $out/share/niri-monitor-flash/main.py
      cp -r ${./monitor-effects} $out/share/niri-monitor-flash/monitor-effects
      makeWrapper ${python}/bin/python3 $out/bin/niri-monitor-flash \
        --add-flags $out/share/niri-monitor-flash/main.py \
        --set GSK_RENDERER gl \
        --set PYOPENGL_PLATFORM egl \
        --set NIRI_MONITOR_EFFECT ${lib.escapeShellArg cfg.effect} \
        --prefix PATH : ${pkgs.niri}/bin \
        --prefix LD_PRELOAD : ${pkgs.gtk4-layer-shell}/lib/libgtk4-layer-shell.so
    '';
  };
in
{
  options.local.desktop.monitorFlash = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show a brief shader effect when focus moves to another Niri monitor.";
    };
    effect = lib.mkOption {
      type = lib.types.enum [ "splatter" "fire" "aurora" ];
      default = "splatter";
      description = "Monitor focus effect; preview all three with niri-monitor-flash --demo.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ monitorFlash ];

    # Niri 세션에서만 모니터 이동을 감지합니다. 한 모니터에서는 표시하지 않습니다.
    systemd.user.services.niri-monitor-flash = {
      Unit = {
        Description = "Shader effect when Niri focus moves to another monitor";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        ConditionEnvironment = "NIRI_SOCKET";
      };
      Service = {
        ExecStart = "${monitorFlash}/bin/niri-monitor-flash";
        Restart = "on-failure";
        RestartSec = 2;
        Environment = [ "GDK_BACKEND=wayland" "GTK_A11Y=none" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
