// Power-on: phosphor dot -> horizontal beam -> full picture.
// Reverse the same timeline for power-off. All colors are premultiplied.
float crt_progress(float time) {
    // Normalize y = 16^t so both endpoints stay exact and speed grows 16-fold.
    return (exp2(4.0 * clamp(time, 0.0, 1.0)) - 1.0) / 15.0;
}

vec4 crt_color(vec3 coords_geo, vec3 size_geo, float power) {
    if (power <= 0.0)
        return vec4(0.0);
    if (power >= 1.0) {
        if (any(lessThan(coords_geo.xy, vec2(0.0)))
                || any(greaterThan(coords_geo.xy, vec2(1.0))))
            return vec4(0.0);
        return texture2D(niri_tex, (niri_geo_to_tex * coords_geo).st);
    }

    vec2 size = max(size_geo.xy, vec2(1.0));
    vec2 pixel = (coords_geo.xy - 0.5) * size;
    // The phosphor beam overshoots by 8%, then settles before the image opens.
    // Reversing this path gives power-off a small outward kick before collapse.
    float beam_time = clamp((power - 0.08) / 0.30, 0.0, 1.0);
    float back = beam_time - 1.0;
    float beam = 1.0 + 2.5 * back * back * back + 1.5 * back * back;
    float picture = smoothstep(0.38, 1.0, power);
    vec2 extent = vec2(mix(min(2.0, size.x * 0.5), size.x * 0.5, beam),
                       mix(min(1.0, size.y * 0.5), size.y * 0.5, picture));
    vec2 source = pixel / max(extent * 2.0, vec2(1.0)) + 0.5;
    vec4 color = vec4(0.0);
    if (all(greaterThanEqual(source, vec2(0.0)))
            && all(lessThanEqual(source, vec2(1.0)))) {
        color = texture2D(niri_tex, (niri_geo_to_tex * vec3(source, 1.0)).st);
    }

    float edge = max(abs(pixel.x) - extent.x, abs(pixel.y) - extent.y);
    float coverage = 1.0 - smoothstep(-0.75, 0.75, edge);
    float flash = 1.0 - smoothstep(0.40, 0.92, power);
    vec4 phosphor = vec4(0.86, 0.94, 1.0, 1.0);
    color = mix(color, phosphor, flash) * coverage;
    // Scanlines and the beam halo fade away as the picture stabilizes.
    float scanline = 0.5 + 0.5 * cos(source.y * size.y * 3.14159265);
    color.rgb *= 1.0 - 0.12 * scanline * (1.0 - picture);
    float halo = exp(-max(edge, 0.0) / 3.0) * 0.22 * flash * (1.0 - color.a);
    color += phosphor * halo;
    // Small soft flares follow the moving tips beyond the window boundary.
    vec2 tip = vec2(abs(pixel.x) - extent.x, pixel.y) / vec2(9.0, 3.0);
    float flare = exp(-dot(tip, tip)) * 0.38 * flash
                  * (1.0 - smoothstep(0.38, 0.55, power));
    color += phosphor * flare * (1.0 - color.a);
    return color * smoothstep(0.0, 0.08, power);
}
