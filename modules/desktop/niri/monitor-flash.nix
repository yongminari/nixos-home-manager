{ pkgs, ... }:

let
  python = pkgs.python3.withPackages (ps: [ ps.pygobject3 ps.pycairo ]);
  monitorFlash = pkgs.stdenvNoCC.mkDerivation {
    pname = "niri-monitor-flash";
    version = "1.0";
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.wrapGAppsHook4 pkgs.gobject-introspection ];
    buildInputs = [ pkgs.gtk4 pkgs.gtk4-layer-shell ];
    installPhase = ''
      mkdir -p $out/bin $out/share/niri-monitor-flash
      cp ${./monitor-flash.py} $out/share/niri-monitor-flash/main.py
      makeWrapper ${python}/bin/python3 $out/bin/niri-monitor-flash \
        --add-flags $out/share/niri-monitor-flash/main.py \
        --set GSK_RENDERER cairo \
        --prefix PATH : ${pkgs.niri}/bin \
        --prefix LD_PRELOAD : ${pkgs.gtk4-layer-shell}/lib/libgtk4-layer-shell.so
    '';
  };
in
{
  home.packages = [ monitorFlash ];

  # Niri 세션에서만 모니터 이동을 감지합니다. 한 모니터에서는 표시하지 않습니다.
  systemd.user.services.niri-monitor-flash = {
    Unit = {
      Description = "Water ripples when Niri focus moves to another monitor";
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
}
