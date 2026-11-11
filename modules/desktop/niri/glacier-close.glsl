// A stationary window melts from its top edge; released color runs downward.
// This is an analytic visual approximation, not a fluid simulation.
float melt_hash(float x) {
    return fract(sin(x * 127.1 + niri_random_seed * 311.7) * 43758.5453);
}

float melt_noise(float x) {
    float cell = floor(x);
    float f = fract(x);
    // Cubic B-spline noise has continuous curvature across cell boundaries.
    // Averaging four random controls avoids pointed peaks and flat shoulders.
    float f2 = f * f;
    float f3 = f2 * f;
    vec4 weights = vec4(pow(1.0 - f, 3.0),
                        3.0 * f3 - 6.0 * f2 + 4.0,
                        -3.0 * f3 + 3.0 * f2 + 3.0 * f + 1.0,
                        f3) / 6.0;
    return dot(weights, vec4(melt_hash(cell - 1.0), melt_hash(cell),
                             melt_hash(cell + 1.0), melt_hash(cell + 2.0)));
}

vec4 melt_sample(vec2 source, vec2 size, float aa) {
    if (source.x < 0.0 || source.x > 1.0 || source.y < 0.0 || source.y > 1.0)
        return vec4(0.0);
    float corner = min(28.0, min(size.x, size.y) * 0.5);
    vec2 q = abs((source - 0.5) * size) - (size * 0.5 - vec2(corner));
    float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner;
    float coverage = 1.0 - smoothstep(-aa, aa, distance);
    return texture2D(niri_tex, (niri_geo_to_tex * vec3(source, 1.0)).st) * coverage;
}

vec4 close_color(vec3 coords_geo, vec3 size_geo) {
    float p = clamp(niri_clamped_progress, 0.0, 1.0);
    if (p >= 1.0)
        return vec4(0.0);

    vec2 uv = coords_geo.xy;
    vec2 size = max(size_geo.xy, vec2(1.0));
    float aa = 1.0 / max(niri_scale, 0.01);
    if (p <= 0.0)
        return melt_sample(uv, size, aa);
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0)
        return vec4(0.0);

    // Fixed spatial variation keeps the melting edge coherent between frames.
    // Stream widths follow logical pixels, including on wide or narrow windows.
    float x = uv.x * size.x;
    float broad = melt_noise(x / 160.0);
    float channels = melt_noise(x / 65.0 + 19.0);
    // Keep the edge's vertical relief in logical pixels too: tall windows
    // should not turn a gentle wave into a steep, sawtooth-like silhouette.
    float delay = min((32.0 * broad + 8.0 * channels) / size.y, 0.10);
    float time = max(p - delay, 0.0);
    float speed = 1.5;
    float front = speed * time;
    float pixel_y = aa / size.y;

    // The lower, unmelted part stays at its original position. Only a narrow
    // wet edge takes on an icy tint; the window remains recognizable.
    vec4 solid = melt_sample(uv, size, aa);
    float wet = (1.0 - smoothstep(0.0, 0.065, uv.y - front))
              * smoothstep(0.0, 0.08, time);
    solid.rgb = mix(solid.rgb, vec3(0.65, 0.85, 0.95) * solid.a, 0.16 * wet);
    solid *= smoothstep(front - pixel_y, front + pixel_y, uv.y);
    vec4 color = solid;

    // A source row s releases at time s/speed, then falls by gravity * age^2:
    // y = s + gravity * (time - s/speed)^2. Solve both inverse branches so
    // newly melted water and older falling streaks can overlap without holes.
    float gravity = mix(5.0, 6.5, broad);
    float discriminant = speed * speed + 4.0 * gravity * (uv.y - front);
    if (time > 0.0 && discriminant >= 0.0) {
        float root = sqrt(discriminant);
        // Feather the folded liquid edge instead of abruptly appearing at
        // the quadratic's turning point, where texture lines otherwise cusp.
        float fold_coverage = smoothstep(0.0, 4.0 * gravity * pixel_y * 3.0,
                                         discriminant);
        for (int branch = 0; branch < 2; branch++) {
            float direction = branch == 0 ? -1.0 : 1.0;
            float age = (speed + direction * root) / (2.0 * gravity);
            float source_y = speed * (time - age);
            if (age <= 0.0 || source_y < 0.0 || source_y > 1.0)
                continue;

            // Older liquid thins into uneven rivulets as it accelerates down.
            float stretch = abs(1.0 - 2.0 * gravity * age / speed);
            float thinning = mix(1.0, smoothstep(0.15, 0.85, channels),
                                 smoothstep(0.03, 0.24, age));
            float opacity = thinning / sqrt(max(1.0, stretch));
            opacity *= 1.0 - smoothstep(0.28, 0.55, age);
            // Fade the source limits over a few output pixels so falling
            // streaks taper softly instead of ending in hard-cut points.
            float tip_width = max(3.0 * pixel_y / max(stretch, 0.2), 0.004);
            opacity *= fold_coverage * smoothstep(0.0, tip_width, source_y)
                     * (1.0 - smoothstep(1.0 - tip_width, 1.0, source_y));
            float sway = 2.0 * sin(x / 80.0 + age * 10.0)
                       * smoothstep(0.0, 0.15, age) / size.x;
            vec4 liquid = melt_sample(vec2(uv.x + sway, source_y), size,
                                      aa / max(stretch, 0.2));
            liquid.rgb = mix(liquid.rgb, vec3(0.55, 0.80, 0.93) * liquid.a,
                             0.22 * smoothstep(0.0, 0.15, age));
            liquid *= opacity;
            color = liquid + color * (1.0 - liquid.a);
        }
    }

    // Clear the last falling water smoothly, even below the original window.
    return color * (1.0 - smoothstep(0.88, 1.0, p));
}
