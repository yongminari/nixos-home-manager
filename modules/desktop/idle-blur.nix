{ config, lib, pkgs, ... }:
let
  cfg = config.local.desktop.monitorIdleRefresh;
  blurFile = "${config.xdg.configHome}/niri/idle-blur.kdl";
  python = pkgs.python3.withPackages (ps: [ ps.pygobject3 ps.pycairo ]);
  overlay = pkgs.stdenvNoCC.mkDerivation {
    pname = "niri-idle-blur";
    version = "1.0";
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.wrapGAppsHook3 pkgs.gobject-introspection ];
    buildInputs = [ pkgs.gtk3 pkgs.gtk-layer-shell ];
    installPhase = ''
      mkdir -p $out/bin
      makeWrapper ${python}/bin/python3 $out/bin/niri-idle-blur \
        --add-flags ${./idle-blur.py} \
        --set NIRI_IDLE_BLUR_CONFIG ${lib.escapeShellArg blurFile} \
        --set NIRI_IDLE_BLUR_TARGET ${lib.escapeShellArg cfg.output} \
        --prefix PATH : ${lib.makeBinPath [ pkgs.niri ]}
    '';
  };
  reset = pkgs.writeShellScript "reset-idle-blur" ''
    mkdir -p ${lib.escapeShellArg "${config.xdg.configHome}/niri"}
    temporary=$(mktemp ${lib.escapeShellArg "${blurFile}.XXXXXX"})
    cat ${./niri/blur-default.kdl} > "$temporary"
    mv -f "$temporary" ${lib.escapeShellArg blurFile}
  '';
in
{
  config = lib.mkIf cfg.blur {
    assertions = [{
      assertion = cfg.enable;
      message = "monitorIdleRefresh.blur requires monitorIdleRefresh.enable.";
    }];
    home.activation.initializeIdleBlur = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
      run ${reset}
    '';
    systemd.user.services.niri-idle-blur = {
      Unit = {
        Description = "Subtle blur before idle monitor power-off";
        PartOf = [ "graphical-session.target" "hypridle.service" ];
        After = [ "graphical-session.target" ];
        ConditionEnvironment = "NIRI_SOCKET";
      };
      Service = {
        ExecStart = "${overlay}/bin/niri-idle-blur";
        ExecStopPost = "${reset}";
        TimeoutStopSec = 3;
        Environment = [ "GDK_BACKEND=wayland" "GTK_A11Y=none" ];
      };
    };
  };
}
