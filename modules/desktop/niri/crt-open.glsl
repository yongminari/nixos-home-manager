vec4 crt_open_color(vec3 coords_geo, vec3 size_geo) {
    float time = clamp(niri_clamped_progress, 0.0, 1.0);
    // Keep the tuned CRT formation intact for the first 400ms of 1000ms.
    if (time < 0.40)
        return crt_color(coords_geo, size_geo, crt_progress(time * 2.5));

    // Stretch vertically to 118%, keeping the width and center fixed.
    // Then use the dust effect's three damped rebounds along the same axis.
    float scale = 1.0 + 0.18 * smoothstep(0.40, 0.475, time);
    if (time >= 0.475)
        scale = 1.0 + opening_rebound(time, 0.475, 0.18);
    vec3 source = vec3(coords_geo.x, (coords_geo.y - 0.5) / scale + 0.5, 1.0);
    return crt_color(source, size_geo, 1.0);
}
