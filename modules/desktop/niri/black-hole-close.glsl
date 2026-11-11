// Original window pixels draining into the circular inlet.
// Keep the existing r^2 sink law, distance-weighted release friction, startup
// response, rectangle-to-disk transport and perspective descent. Each source
// pixel has a stable random friction class; no round particle sprites or sand shading.
// Backtrace five flow classes instead of gathering large particle sprites.
// This is a visual flow approximation, not a grain-collision CFD solver.
// INK_FLOW uses one continuous, gently swirling sheet of window color instead
// of the five independently moving pixel classes.

float flow_hash(vec2 p) {
    p += vec2(niri_random_seed * 71.0, niri_random_seed * 113.0);
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float flow_friction_weight(float original_squared, float reach_squared) {
    // Use Euclidean distance in the actual window, not angle or a fixed aspect
    // ratio. Keep the farthest corner at 50%, with less resistance nearer in.
    // Extend the same polynomial outside the window for the inverse solver.
    return 0.25 + 0.25 * original_squared / reach_squared;
}

float flow_release(float original_squared, float friction, float reach_squared) {
    return 0.18 * friction * original_squared / reach_squared
         * flow_friction_weight(original_squared, reach_squared);
}

// Concentric rectangle-to-disk transport. Unlike simply normalizing the radius,
// it also redistributes angle: pixels from crowded corners move toward the
// short-side sectors as the population rounds out. The center remains fixed.
vec2 flow_disk(vec2 point, vec2 half_size) {
    vec2 normalized = point / half_size;
    vec2 a = abs(normalized);
    float shell = max(a.x, a.y);
    if (shell < 0.000001)
        return vec2(0.0);
    float angle = a.x >= a.y ? 0.78539816 * a.y / a.x
                            : 1.57079633 - 0.78539816 * a.x / a.y;
    return 0.5 * shell * vec2(cos(angle), sin(angle)) * sign(point);
}

// Original point corresponding to one unit of disk radius in the first quadrant.
vec2 flow_rectangle_ray(float angle, vec2 half_size) {
    vec2 edge = angle <= 0.78539816 ? vec2(1.0, angle / 0.78539816)
                                  : vec2((1.57079633 - angle) / 0.78539816, 1.0);
    return 2.0 * half_size * edge;
}

// Invert the evolving transport once per pixel. It is monotonic in angle, so
// bisection avoids folds and also lets the gather find laterally moving pixels.
vec2 flow_query(vec2 point, vec2 half_size, float spread) {
    if (spread <= 0.000001)
        return flow_disk(point, half_size);
    vec2 a = abs(point);
    float lower = 0.0;
    float upper = 1.57079633;
    for (int i = 0; i < 16; i++) {
        float angle = 0.5 * (lower + upper);
        vec2 ray = mix(flow_rectangle_ray(angle, half_size), vec2(cos(angle), sin(angle)), spread);
        if (ray.y * a.x < ray.x * a.y)
            lower = angle;
        else
            upper = angle;
    }
    float angle = 0.5 * (lower + upper);
    vec2 direction = vec2(cos(angle), sin(angle));
    vec2 ray = mix(flow_rectangle_ray(angle, half_size), direction, spread);
    return direction * sign(point) * (length(point) / max(length(ray), 0.000001));
}

float flow_response(float age) {
    age = max(age, 0.0);
    return max(age - 0.045 * (1.0 - exp(-age / 0.045)), 0.0);
}

// Invert each friction class separately so delayed pixels do not vanish merely
// because they move outside the neighborhood of an average-friction trajectory.
float flow_source_squared(float target_squared, float time, float friction,
                           float reach_squared, float strength, float material_scale_squared) {
    float original = target_squared + strength * flow_response(time);
    for (int i = 0; i < 6; i++) {
        float material_squared = original * material_scale_squared;
        float age = max(time - flow_release(material_squared, friction, reach_squared), 0.0);
        float residual = original - strength * flow_response(age) - target_squared;
        // Include the derivative of distance-dependent friction in the inverse.
        float release_slope = 0.18 * friction * material_scale_squared / reach_squared
                            * (0.25 + 0.5 * material_squared / reach_squared);
        float slope = 1.0 + strength * release_slope * (1.0 - exp(-age / 0.045));
        original = max(original - residual / slope, target_squared);
    }
    return original;
}

float flow_outline(vec2 point, vec2 size_geo, float corner) {
    vec2 q = abs(point) - (size_geo * 0.5 - vec2(corner));
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner;
}

vec4 close_color(vec3 coords_geo, vec3 size_geo) {
    float time = clamp(niri_clamped_progress, 0.0, 1.0);
    if (time <= 0.0) {
        if (coords_geo.x < 0.0 || coords_geo.x > 1.0
                || coords_geo.y < 0.0 || coords_geo.y > 1.0)
            return vec4(0.0);
        return texture2D(niri_tex, (niri_geo_to_tex * coords_geo).st);
    }
    if (time >= 1.0)
        return vec4(0.0);

    float short_side = max(min(size_geo.x, size_geo.y), 1.0);
    vec2 aspect = size_geo.xy / short_side;
    vec2 half_size = aspect * 0.5;
    vec2 point = (coords_geo.xy - 0.5) * aspect;
    float radius = length(point);
    float scale = max(niri_scale, 0.01);
    float pixel = 1.0 / (short_side * scale);
    float corner = min(28.0, short_side * 0.5);
    float reach_squared = dot(half_size, half_size);
    float mouth = 0.01625;
    float formation = smoothstep(0.0, 0.10, time);
    float collapse = 1.0 - smoothstep(0.90, 1.0, time);
    float horizon = mouth * formation * collapse;
    float spread = smoothstep(0.12, 0.42, time);
    float flow_mouth = mouth / length(aspect);
    float strength = (0.25 - flow_mouth * flow_mouth)
                   / flow_response(0.80 - 0.18 * 1.15);

    vec4 color = vec4(0.0);
    vec2 flow_point = flow_query(point, half_size, spread);
    float flow_radius = length(flow_point);
#ifdef INK_FLOW
    // Begin curling only once the rectangle has become a disk, so its outer
    // corners do not rotate out of the original silhouette. The inner liquid
    // turns farther than the outer liquid, stretching colors into ink ribbons.
    float curl = 1.8 * smoothstep(0.42, 0.85, time)
               * exp(-5.0 * flow_radius);
    float c = cos(curl);
    float s = sin(curl);
    flow_point = mat2(c, -s, s, c) * flow_point;
#endif
    float flow_angle = flow_radius > 0.000001
        ? atan(abs(flow_point.y), abs(flow_point.x)) : 0.0;
    vec2 material_ray = flow_rectangle_ray(flow_angle, half_size) * sign(flow_point);
    float material_scale_squared = dot(material_ray, material_ray);
    float query_time = time;
    float target_squared = flow_radius * flow_radius;
    if (flow_radius < flow_mouth) {
        // Invert the same z ~ dt^2 descent and pinhole scale 1/(1+z/f).
        query_time -= sqrt(max(flow_mouth / max(flow_radius, pixel * 0.05) - 1.0, 0.0) / 400.0);
        target_squared = flow_mouth * flow_mouth;
    }
    if (query_time >= 0.0 && radius <= sqrt(reach_squared) + pixel) {
#ifdef INK_FLOW
        // A single backtrace keeps neighboring pixels connected: no random
        // class rejection, overlapping grains, or holes between flow classes.
        float source_squared = flow_source_squared(target_squared, query_time, 1.0,
            reach_squared, strength, material_scale_squared);
        vec2 original_point = material_ray * sqrt(source_squared);
        vec2 source = original_point / aspect + 0.5;
        if (source.x >= 0.0 && source.x <= 1.0 && source.y >= 0.0 && source.y <= 1.0) {
            float coverage = 1.0 - smoothstep(-1.0 / scale, 1.0 / scale,
                flow_outline(original_point * short_side, size_geo.xy, corner));
            color = texture2D(niri_tex, (niri_geo_to_tex * vec3(source, 1.0)).st)
                  * coverage * collapse;
        }
#else
        for (int group = 0; group < 5; group++) {
            float friction = 0.85 + 0.075 * float(group);
            float source_squared = flow_source_squared(target_squared, query_time, friction,
                reach_squared, strength, material_scale_squared);
            vec2 original_point = material_ray * sqrt(source_squared);
            vec2 source = original_point / aspect + 0.5;
            if (source.x < 0.0 || source.x >= 1.0 || source.y < 0.0 || source.y >= 1.0)
                continue;

            // Hash original physical pixels, not output coordinates or time.
            // The same pixel follows the same trajectory throughout the close.
            vec2 source_pixel = floor(source * size_geo.xy * scale);
            if (floor(flow_hash(source_pixel) * 5.0) != float(group))
                continue;
            float coverage = 1.0 - smoothstep(-1.0 / scale, 1.0 / scale,
                flow_outline(original_point * short_side, size_geo.xy, corner));
            // Preserve the source image and its premultiplied alpha. The flow
            // compresses pixels naturally; no round footprint, jitter or tint.
            vec4 sample_color = texture2D(niri_tex, (niri_geo_to_tex * vec3(source, 1.0)).st);
            sample_color *= coverage * collapse;
            color = sample_color + color * (1.0 - sample_color.a);
        }
#endif
    }

    float shadow = (1.0 - smoothstep(max(0.0, horizon - pixel), horizon + pixel, radius))
                 * formation * collapse;
    color = vec4(vec3(0.0), shadow) + color * (1.0 - shadow);
    float ring_radius = horizon * 1.12;
    float ring_distance = abs(radius - ring_radius);
    float width = max(0.000625 * collapse, pixel * 0.5);
    float rim = 1.0 - smoothstep(width, width + pixel, ring_distance);
    float glow = exp(-pow(ring_distance / max(0.003 * collapse, pixel), 2.0));
    float light_alpha = clamp(0.85 * rim + 0.22 * glow, 0.0, 1.0) * formation * collapse;
    vec3 light_color = mix(vec3(1.0, 0.55, 0.18), vec3(1.0, 0.94, 0.78), rim);
    return vec4(light_color * light_alpha, light_alpha) + color * (1.0 - light_alpha);
}
