// Stylized black-hole absorption, drawn only from the closing window's texture.
float black_hole_noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    vec4 hashes = fract(sin(vec4(dot(cell, vec2(127.1, 311.7)),
                                dot(cell + vec2(1.0, 0.0), vec2(127.1, 311.7)),
                                dot(cell + vec2(0.0, 1.0), vec2(127.1, 311.7)),
                                dot(cell + vec2(1.0), vec2(127.1, 311.7)))) * 43758.5453);
    return mix(mix(hashes.x, hashes.y, f.x), mix(hashes.z, hashes.w, f.x), f.y);
}

vec4 close_color(vec3 coords_geo, vec3 size_geo) {
    float progress = clamp(niri_clamped_progress, 0.0, 1.0);
    if (progress <= 0.0) {
        if (coords_geo.x < 0.0 || coords_geo.x > 1.0
                || coords_geo.y < 0.0 || coords_geo.y > 1.0)
            return vec4(0.0);
        return texture2D(niri_tex, (niri_geo_to_tex * coords_geo).st);
    }
    if (progress >= 1.0)
        return vec4(0.0);

    float short_side = max(min(size_geo.x, size_geo.y), 1.0);
    vec2 aspect = size_geo.xy / short_side;
    vec2 point = (coords_geo.xy - 0.5) * aspect;
    float radius = length(point);
    vec2 radial = point / max(radius, 0.0001);
    float pixel = 1.0 / short_side;
    // Time the final approach against the actual rounded outline, so its last
    // fragments do not disappear before the slow tail of the intake curve.
    float corner_radius = min(28.0, short_side * 0.5) / short_side;
    float reach = length(aspect * 0.5 - vec2(corner_radius)) + corner_radius;

    // Finish swallowing all window pixels before the horizon starts closing.
    // Keep a brief full-size hold between intake and collapse.
    float intake_end = 0.82;
    float collapse_start = 0.90;
    float formation = smoothstep(0.0, 0.10, progress);
    float collapse = 1.0 - smoothstep(collapse_start, 1.0, progress);
    float hole_scale = 0.25;
    float horizon = 0.065 * hole_scale * formation * collapse;
    // Accelerate initially, then give the last fragments a readable approach.
    // Join the final easing with matching speed; its cubic remaining distance
    // removes the infinite terminal radial speed of the square-root sink flow.
    float intake = clamp((progress - 0.03) / (intake_end - 0.03), 0.0, 1.0);
    if (intake > 0.55) {
        float tail = (intake - 0.55) / 0.45;
        float remaining = 1.0 - tail;
        float eased_tail = 1.0 - remaining * remaining * remaining * (1.0 + 2.0 * tail);
        intake = 0.55 + 0.45 * eased_tail;
    }
    float swallowed = intake * intake;
    float source_radius = sqrt(radius * radius + reach * reach * swallowed);

    // Angular deflection depends on inward travel, never on a free spin clock.
    // Outer material stretches radially; near the horizon it bends into arcs.
    float influence = 0.36;
    float core = 0.03;
    float bend = 1.0 - smoothstep(core, influence, radius);
    float source_bend = 1.0 - smoothstep(core, influence, source_radius);
    float turn = 3.2 * (bend - source_bend);
    // Coherent per-window turbulence bends the flow without changing its radial
    // acceleration. Fade it at the horizon and outside the attraction region.
    vec2 seed = vec2(niri_random_seed * 71.0, niri_random_seed * 113.0);
    vec2 drift = vec2(2.5, -1.8) * progress;
    float turbulence = 0.65 * black_hole_noise(point * 11.0 + seed + drift)
                     + 0.35 * black_hole_noise(point * 23.0 + seed - drift * 0.7);
    float wobble = (bend - source_bend) * smoothstep(horizon * 1.4, 0.08, radius);
    turn += 0.55 * (turbulence - 0.5) * wobble;
    vec2 direction = vec2(cos(turn) * radial.x + sin(turn) * radial.y,
                          -sin(turn) * radial.x + cos(turn) * radial.y);
    vec2 source = direction * source_radius / aspect + 0.5;

    vec4 color = vec4(0.0);
    // At intake_end the sampled radius exceeds even the farthest window corner;
    // only the horizon and its rim remain, with no window-wide fade-out.
    if (progress < intake_end
            && source_radius < reach
            && source.x >= 0.0 && source.x <= 1.0 && source.y >= 0.0 && source.y <= 1.0) {
        float corner = min(28.0, short_side * 0.5);
        vec2 q = abs((source - 0.5) * size_geo.xy)
               - (size_geo.xy * 0.5 - vec2(corner));
        float outline = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner;
        float zone = clamp((radius - core) / (influence - core), 0.0, 1.0);
        float source_zone = clamp((source_radius - core) / (influence - core), 0.0, 1.0);
        float source_slope = radius / max(source_radius, 0.0001);
        float turn_slope = 3.2 * 6.0 * abs(zone * (1.0 - zone)
                          - source_zone * (1.0 - source_zone) * source_slope)
                        / (influence - core);
        float aa = max(1.0, source_radius / max(radius, pixel)
                            + source_radius * (turn_slope + 10.0 * wobble));
        float coverage = 1.0 - smoothstep(-aa, aa, outline);
        color = texture2D(niri_tex, (niri_geo_to_tex * vec3(source, 1.0)).st) * coverage;
        color.rgb *= mix(0.45, 1.0, smoothstep(horizon, influence, radius));
    }

    // A narrow warm rim gives the incoming material a visible destination.
    // Both the rim and dark core shrink to a point, rather than leaving a ring.
    float ring_radius = horizon * 1.12;
    float ring_distance = abs(radius - ring_radius);
    float width = max(0.0025 * hole_scale * collapse, pixel * 0.5);
    float rim = 1.0 - smoothstep(width, width + pixel, ring_distance);
    float glow_width = max(0.012 * hole_scale * collapse, pixel);
    float glow = exp(-pow(ring_distance / glow_width, 2.0));
    float light_alpha = clamp(0.85 * rim + 0.22 * glow, 0.0, 1.0) * formation * collapse;
    vec3 light_color = mix(vec3(1.0, 0.55, 0.18), vec3(1.0, 0.94, 0.78), rim);
    color = vec4(light_color * light_alpha, light_alpha) + color * (1.0 - light_alpha);
    float shadow = (1.0 - smoothstep(max(0.0, horizon - pixel), horizon + pixel, radius))
                 * formation * collapse;
    return vec4(vec3(0.0), shadow) + color * (1.0 - shadow);
}
