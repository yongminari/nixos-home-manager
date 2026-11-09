// A billowing explosion expands into the window: cloud and content share one front.
float dust_hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float dust_noise(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(dust_hash(cell), dust_hash(cell + vec2(1.0, 0.0)), f.x),
               mix(dust_hash(cell + vec2(0.0, 1.0)), dust_hash(cell + vec2(1.0)), f.x), f.y);
}

float dust_fbm(vec2 p) {
    float value = 0.0;
    float weight = 0.5333333;
    for (int i = 0; i < 4; i++) {
        value += weight * dust_noise(p);
        p = p * 2.03 + vec2(7.1, 3.7);
        weight *= 0.5;
    }
    return value;
}

vec4 open_color(vec3 coords_geo, vec3 size_geo) {
    float progress = clamp(niri_clamped_progress, 0.0, 1.0);
    if (progress <= 0.0)
        return vec4(0.0);
    if (progress >= 1.0) {
        if (coords_geo.x < 0.0 || coords_geo.x > 1.0
                || coords_geo.y < 0.0 || coords_geo.y > 1.0)
            return vec4(0.0);
        return texture2D(niri_tex, (niri_geo_to_tex * coords_geo).st);
    }

    float short_side = max(min(size_geo.x, size_geo.y), 1.0);
    vec2 aspect = size_geo.xy / short_side;
    vec2 point = (coords_geo.xy - 0.5) * aspect;
    float radius = length(point);
    float reach = length(aspect * 0.5) + 0.12;
    float formation = smoothstep(0.0, 0.06, progress);
    float front = reach * (1.0 - pow(1.0 - progress, 1.8));
    if (radius > max(front * 1.4 + 0.08, reach))
        return vec4(0.0);

    // Advect dust outward independently of the expanding plume's silhouette.
    // Along each ray, noise features travel at a fixed radial speed instead of
    // keeping the same relative position on an enlarging cloud texture.
    vec2 seed = vec2(niri_random_seed * 71.0, niri_random_seed * 113.0);
    vec2 radial = radius > 0.0001 ? point / radius : vec2(1.0, 0.0);
    // Backtrace through the outward velocity in physical coordinates. Keep the
    // noise two-dimensional so billows remain rounded instead of radial stripes.
    float traveled = reach * 0.48 * progress;
    vec2 flow = radial * max(radius - traveled, 0.0) * 8.0;
    vec2 rolling = vec2(1.7, -1.3) * progress;
    vec2 warp = vec2(dust_noise(flow * 0.65 + seed + rolling),
                     dust_noise(flow * 0.65 + seed + vec2(17.3, 9.2) - rolling * 0.7));
    vec2 cloud_coords = flow + (warp - 0.5) * 1.6 + seed;
    float billow = dust_fbm(cloud_coords);
    // Fine dust overtakes the larger rolling billows.
    vec2 fine_flow = radial * max(radius - reach * 0.70 * progress, 0.0) * 18.0;
    float detail = dust_noise(fine_flow + seed + (warp - 0.5) * 2.0);
    float silhouette = dust_fbm(radial * max(radius - reach * 0.35 * progress, 0.0) * 5.0 + seed);
    float edge_radius = front * (0.83 + 0.38 * silhouette)
                      + (detail - 0.5) * 0.035 * formation;
    float cloud_mask = 1.0 - smoothstep(edge_radius - 0.035, edge_radius + 0.035, radius);
    float puff = smoothstep(0.25, 0.70, billow + 0.18 * (detail - 0.5));

    // Soft shaded grey-brown dust, with lighter tops and darker folds.
    float light_sample = dust_fbm(cloud_coords + vec2(-0.18, 0.22));
    float lighting = clamp(0.25 + 0.85 * puff + 2.5 * (light_sample - billow), 0.0, 1.0);
    vec3 dust_color = mix(vec3(0.22, 0.20, 0.18), vec3(0.67, 0.64, 0.58), lighting);
    float age = max(progress - 0.55 * radius / reach, 0.0);
    float dust_mix = (0.65 + 0.35 * puff)
                   * (1.0 - smoothstep(0.12, 0.48, age))
                   * (1.0 - smoothstep(0.65, 1.0, progress));

    // Expand content along each ray at the same front as the cloud. Near edges
    // arrive first and corners last, so the beginning remains a billowing disk
    // rather than a scaled rectangle or a cloud covering a stationary window.
    float corner = min(28.0, short_side * 0.5);
    float corner_radius = corner / short_side;
    vec2 ray = abs(radial);
    float destination = 0.5 / max(max(ray.x / aspect.x, ray.y / aspect.y), 0.0001);
    vec2 corner_center = aspect * 0.5 - vec2(corner_radius);
    if (all(greaterThan(ray * destination, corner_center))) {
        float along = dot(ray, corner_center);
        destination = along + sqrt(max(along * along - dot(corner_center, corner_center)
                                         + corner_radius * corner_radius, 0.0));
    }
    float settled = smoothstep(0.78, 1.0, progress);
    float moving_edge = mix(min(max(edge_radius, 0.001), destination), destination, settled);
    float expansion = max(moving_edge / destination, 0.001);
    vec2 source = point / (aspect * expansion) + 0.5;
    if (source.x < 0.0 || source.x > 1.0 || source.y < 0.0 || source.y > 1.0)
        return vec4(0.0);

    vec2 q = abs((source - 0.5) * size_geo.xy)
           - (size_geo.xy * 0.5 - vec2(corner));
    float outline = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner;
    float aa = 1.5 / expansion;
    float coverage = (1.0 - smoothstep(-aa, aa, outline))
                   * mix(cloud_mask, 1.0, settled) * formation;
    vec4 window_color = texture2D(niri_tex, (niri_geo_to_tex * vec3(source, 1.0)).st);
    // The same moving material turns from dust into the window's own colors.
    return mix(window_color, vec4(dust_color, 1.0), dust_mix) * coverage;
}
