// A cloud carries the expanding front, revealing the window only on arrival.
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
    float time = clamp(niri_clamped_progress, 0.0, 1.0);
    if (time <= 0.0)
        return vec4(0.0);
    if (time >= 1.0) {
        if (coords_geo.x < 0.0 || coords_geo.x > 1.0
                || coords_geo.y < 0.0 || coords_geo.y > 1.0)
            return vec4(0.0);
        return texture2D(niri_tex, (niri_geo_to_tex * coords_geo).st);
    }

    // Carry the plume's outward velocity through full size into the first peak.
    float formation_end = 0.40;
    float first_peak = 0.475;
    float acceleration_power = 2.4;
    float progress = pow(clamp(time / formation_end, 0.0, 1.0), acceleration_power);
    float shape_blend = smoothstep(0.60, 1.0, progress);
    float overshoot = 0.18;
    // This envelope reaches full size with the same slope as progress. Unlike
    // smoothstep, it does not stop at full size before the overshoot starts.
    float spring_scale = 1.0 - 0.25 * (1.0 - pow(progress, 4.0));
    if (time >= formation_end && time < first_peak) {
        float duration = first_peak - formation_end;
        float u = (time - formation_end) / duration;
        float arrival_speed = acceleration_power / formation_end;
        // Hermite join: preserve incoming velocity, then brake to rest at 118%.
        float carry = u * (1.0 - u) * (1.0 - u);
        float arrive = u * u * (3.0 - 2.0 * u);
        spring_scale = 1.0 + arrival_speed * duration * carry + overshoot * arrive;
    }
    if (time >= first_peak) {
        // Three rebounds: each opposite extremum has half the prior amplitude.
        // Each half-cycle lasts 72% of the previous one as the motion settles.
        // Invert the geometric duration sum while keeping six turns before 1.0.
        float rebound_time = clamp((time - first_peak) / (1.0 - first_peak), 0.0, 1.0);
        float duration_ratio = 0.72;
        float phase = log(1.0 - rebound_time * (1.0 - pow(duration_ratio, 6.0)))
                    / log(duration_ratio);
        phase = clamp(phase, 0.0, 6.0);
        float segment = min(floor(phase), 5.0);
        float amplitude = overshoot * pow(0.5, segment)
                        * (mod(segment, 2.0) < 1.0 ? 1.0 : -1.0);
        float next_amplitude = segment < 5.0 ? -0.5 * amplitude : 0.0;
        // Stop smoothly at every turn, even as the intervals become shorter.
        float blend = 0.5 - 0.5 * cos(3.14159265 * (phase - segment));
        spring_scale = 1.0 + mix(amplitude, next_amplitude, blend);
    }

    // Bow the four side centers outward and inward, with quieter corners.
    // Use window-relative directions so wide and tall windows behave alike.
    // This weight is constant along each ray, making the inverse warp exact.
    vec2 centered = coords_geo.xy - 0.5;
    vec2 squared = centered * centered;
    float side_direction = (squared.x - squared.y)
                         / max(squared.x + squared.y, 0.000001);
    // Keep the explosion isotropic; introduce side/corner weighting only as
    // the circular plume takes on the final window shape.
    float spring_weight = mix(1.0, mix(0.20, 1.0, side_direction * side_direction), shape_blend);
    spring_scale = 1.0 + (spring_scale - 1.0) * spring_weight;

    float short_side = max(min(size_geo.x, size_geo.y), 1.0);
    vec2 aspect = size_geo.xy / short_side;
    vec2 point = centered * aspect / spring_scale;
    float radius = length(point);
    float reach = length(aspect * 0.5) + 0.12;
    float formation = smoothstep(0.0, 0.06, progress);
    // Radius follows time^2.4: do not cancel its acceleration with an ease-out.
    float front = 0.5 * progress;
    if (radius > max(front * 1.4 + 0.08, reach))
        return vec4(0.0);

    // Advect billows with the accelerating plume in material coordinates.
    // Do not clamp a radial backtrace to zero: that collapses the entire inner
    // cloud onto one noise sample and turns it into a flat, solid-colored disk.
    vec2 seed = vec2(niri_random_seed * 71.0, niri_random_seed * 113.0);
    vec2 radial = radius > 0.0001 ? point / radius : vec2(1.0, 0.0);
    vec2 plume_point = point / max(front, 0.015);
    vec2 flow = plume_point * 3.5;
    vec2 rolling = vec2(1.7, -1.3) * progress;
    vec2 warp = vec2(dust_noise(flow * 0.65 + seed + rolling),
                     dust_noise(flow * 0.65 + seed + vec2(17.3, 9.2) - rolling * 0.7));
    vec2 cloud_coords = flow + (warp - 0.5) * 1.6 + seed;
    float billow = dust_fbm(cloud_coords);
    // Fine structure rides on the larger outward-moving billows.
    vec2 fine_flow = plume_point * 11.0;
    float detail = dust_noise(fine_flow + seed + (warp - 0.5) * 2.0);
    float silhouette = dust_fbm(radial * 3.0 + seed + rolling * 0.2);
    float edge_radius = front * (0.97 + 0.06 * silhouette)
                      + (detail - 0.5) * 0.008 * formation;
    float puff = smoothstep(0.25, 0.70, billow + 0.18 * (detail - 0.5));

    // Soft shaded grey-brown dust, with lighter tops and darker folds.
    float light_sample = dust_fbm(cloud_coords + vec2(-0.18, 0.22));
    float lighting = clamp(0.25 + 0.85 * puff + 2.5 * (light_sample - billow), 0.0, 1.0);
    vec3 dust_color = mix(vec3(0.22, 0.20, 0.18), vec3(0.67, 0.64, 0.58), lighting);
    // Keep the entire expansion cloudy. Reveal the content only in the final
    // 20 ms of arrival, completing before the first spring overshoot begins.
    float window_reveal = smoothstep(formation_end - 0.02, formation_end, time);
    float cloud_alpha = 0.78 + 0.22 * puff;

    // Map every ray of the window into the circular plume. Do not clamp that
    // plume against the rectangular destination: only the late morph shapes it.
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
    float moving_edge = mix(max(edge_radius, 0.001), destination, shape_blend);
    float expansion = max(moving_edge / destination, 0.001);
    vec2 source = point / (aspect * expansion) + 0.5;
    if (source.x < 0.0 || source.x > 1.0 || source.y < 0.0 || source.y > 1.0)
        return vec4(0.0);

    vec2 q = abs((source - 0.5) * size_geo.xy)
           - (size_geo.xy * 0.5 - vec2(corner));
    float outline = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner;
    float aa = 1.5 / (expansion * spring_scale);
    float coverage = (1.0 - smoothstep(-aa, aa, outline))
                   * formation;
    vec4 window_color = texture2D(niri_tex, (niri_geo_to_tex * vec3(source, 1.0)).st);
    // Premultiply the cloud so its thinner folds reveal the desktop, not a
    // prematurely visible window texture. Geometry and its timing stay shared.
    vec4 cloud_color = vec4(dust_color * cloud_alpha, cloud_alpha);
    return mix(cloud_color, window_color, window_reveal) * coverage;
}
