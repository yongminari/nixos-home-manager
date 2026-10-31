{ config, lib, pkgs, ... }:

let
  templateText = ''
    animations {
      window-close {
        duration-ms 750
        curve "linear"
        custom-shader r#"
          ${builtins.readFile ./genie.glsl}
          vec4 close_color(vec3 coords_geo, vec3 size_geo) {
            return genie_color(coords_geo, size_geo, niri_clamped_progress, @SIDE@);
          }
        "#
      }
    }
  '';
  template = pkgs.writeText "genie-close-template.kdl" templateText;
  defaultClose = pkgs.writeText "genie-close-default.kdl"
    (lib.replaceStrings [ "@SIDE@" ] [ "1.0" ] templateText);
  helper = pkgs.writeShellApplication {
    name = "niri-adaptive-close";
    runtimeInputs = [ pkgs.niri pkgs.python3 ];
    text = ''
      exec python3 ${./adaptive-close.py} ${template} "$@"
    '';
  };
in
{
  config = lib.mkIf config.local.desktop.adaptiveGenieClose {
    assertions = [{
      assertion = config.local.desktop.windowAnimation == "genie";
      message = "adaptiveGenieClose requires windowAnimation = genie";
    }];
    home.packages = [ helper ];
    # 런타임에 셰이더 방향을 바꾸는 파일입니다. 새 세대 적용 시 기본값으로 초기화합니다.
    home.activation.initializeGenieClose = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
      run mkdir -p ${lib.escapeShellArg "${config.xdg.configHome}/niri"}
      run install -m 600 ${defaultClose} ${lib.escapeShellArg "${config.xdg.configHome}/niri/genie-close.kdl"}
    '';
  };
}
