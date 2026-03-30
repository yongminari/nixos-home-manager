{ config, pkgs, ... }:

{
  xdg.configFile."hypr/hyprlock.conf".text = ''
    background {
        monitor =
        path = screenshot
        blur_passes = 2
    }

    label {
        monitor =
        text = $TIME
        color = rgb(cba6f7)
        font_size = 90
        font_family = Maple Mono NF Bold
        position = 0, 80
        halign = center
        valign = center
    }

    input-field {
        monitor =
        size = 250, 60
        outline_thickness = 2
        dots_size = 0.2
        dots_spacing = 0.2
        dots_center = true
        outer_color = rgb(cba6f7)
        inner_color = rgb(313244)
        font_color = rgb(cdd6f4)
        fade_on_empty = false
        placeholder_text = <i>Input Password...</i>
        hide_input = false
        position = 0, -120
        halign = center
        valign = center
    }
  '';
}
