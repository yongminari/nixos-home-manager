# 닫기 효과는 지니와 CRT 중 무작위로 선택하며, 지니는 다음 포커스 방향을 따릅니다.
side:
''
animations {
  window-close {
    duration-ms 550
    curve "linear"
    custom-shader r#"
      ${builtins.readFile ./genie.glsl}
      ${builtins.readFile ./crt.glsl}
      vec4 close_color(vec3 coords_geo, vec3 size_geo) {
        if (niri_random_seed < 0.5)
          return genie_color(coords_geo, size_geo, niri_clamped_progress, ${side});
        // CRT completes in 400ms within the 550ms shared timeline.
        return crt_color(coords_geo, size_geo,
            1.0 - crt_progress(niri_clamped_progress * 1.375));
      }
    "#
  }
}
''
