side:
''
animations {
  window-close {
    duration-ms 750
    curve "linear"
    custom-shader r#"
      ${builtins.readFile ./genie.glsl}
      vec4 close_color(vec3 coords_geo, vec3 size_geo) {
        return genie_color(coords_geo, size_geo, niri_clamped_progress, ${side});
      }
    "#
  }
}
''
