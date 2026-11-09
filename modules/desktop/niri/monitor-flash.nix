{ config, lib, pkgs, ... }:

let
  cfg = config.local.desktop.monitorFlash;
  python = pkgs.python3.withPackages (ps: [ ps.pygobject3 ps.pycairo ps.pyopengl ps.numpy ps.pillow ]);
  monitorFlash = pkgs.stdenvNoCC.mkDerivation {
    pname = "niri-monitor-flash";
    version = "2.0";
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.wrapGAppsHook4 pkgs.gobject-introspection ];
    buildInputs = [ pkgs.gtk4 pkgs.gtk4-layer-shell ];
    installPhase = ''
      mkdir -p $out/bin $out/share/niri-monitor-flash
      cp ${./monitor-flash.py} $out/share/niri-monitor-flash/main.py
      cp ${./screen-drop.glsl} $out/share/niri-monitor-flash/screen-drop.glsl
      cp -r ${./monitor-effects} $out/share/niri-monitor-flash/monitor-effects
      makeWrapper ${python}/bin/python3 $out/bin/niri-monitor-flash \
        --add-flags $out/share/niri-monitor-flash/main.py \
        --set GSK_RENDERER gl \
        --set PYOPENGL_PLATFORM egl \
        --set NIRI_MONITOR_EFFECT ${lib.escapeShellArg cfg.effect} \
        --set NIRI_WINDOW_OPEN_EFFECT ${if cfg.windowOpen then "1" else "0"} \
        --set NIRI_WINDOW_CLOSE_EFFECT ${if cfg.windowClose then "1" else "0"} \
        --prefix PATH : ${lib.makeBinPath [ pkgs.niri pkgs.grim ]} \
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
      type = lib.types.enum [ "screen-ripple" "splatter" "fire" "aurora" ];
      default = "screen-ripple";
      description = "Monitor focus effect; screen-ripple distorts only a single thick ring expanding from the center over 0.5 seconds. Preview with niri-monitor-flash --effect screen-ripple --preview.";
    };
    wallpaperRipple = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Also ripple the Noctalia wallpaper on monitor focus changes, except in screen-ripple mode.";
    };
    windowClose = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Show a reversed screen ripple when a window closes on a visible workspace.";
    };
    windowOpen = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Also show the selected monitor effect when a new window opens on a visible workspace.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ monitorFlash ];

    # Niri 세션에서 모니터 이동과 창 열기/닫기를 감지합니다.
    systemd.user.services.niri-monitor-flash = {
      Unit = {
        Description = "Shader effect on Niri monitor focus changes and window lifecycle events";
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
