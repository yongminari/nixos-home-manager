{ ... }:

{
  local.desktop = {
    scale = "1.0";
    isLaptop = false;
    outputs = {
      left = "Hexium Ltd. 40LGD5KGM 0000000000000";
      right = "Samsung Electric Company SAMSUNG Unknown";
    };
    extraConfig = ''
      output "Hexium Ltd. 40LGD5KGM 0000000000000" {
          mode "5120x2160@120"
          scale 1.25
          position x=0 y=0
      }
      output "Samsung Electric Company SAMSUNG Unknown" {
          off
          mode "3840x2160@60"
          scale 1.25
          position x=4096 y=0
      }
    '';
  };

  local.desktop.chromeArgs = [ "--ozone-platform=wayland" "--enable-features=WaylandWindowDecorations" ];
}
