// Sand entrained by a circular suction inlet, with bulk lateral rearrangement.
// Relax the rectangular population toward circular packing as it drains; this
// geometric closure approximates filling vacant sectors, not individual collisions.
// In these flow coordinates a sink decreases r^2 with integrated flux. Applying
// that law directly in window coordinates would leave long-lived corner lobes.
// A first-order startup response avoids an instantaneous velocity jump. Static
// friction delays entrainment by mu*r0^2; five fixed mu values span 0.85..1.15.
// Distance weighting increases from 25% at the center to 50% at the corners.
// This is a visual flow/particle approximation, not a grain-collision CFD solver.
// https://farside.ph.utexas.edu/teaching/336L/Fluid/node71.html
// https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/drag-equation/
// Lateral granular rearrangement: https://web.mit.edu/bazant/www/papers/pdf/Choi_2005_J_Phys_Cond_Matt_GF3.pdf

float sand_hash(vec2 p) {
    p += vec2(niri_random_seed * 71.0, niri_random_seed * 113.0);
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float sand_friction_weight(float original_squared, float reach_squared) {
    // Use Euclidean distance in the actual window, not angle or a fixed aspect
    // ratio. Keep the farthest corner at 50%, with less resistance nearer in.
    // Extend the same polynomial outside the window for the inverse solver.
    return 0.25 + 0.25 * original_squared / reach_squared;
}

float sand_release(float original_squared, float friction, float reach_squared) {
    return 0.18 * friction * original_squared / reach_squared
         * sand_friction_weight(original_squared, reach_squared);
}

// Concentric rectangle-to-disk transport. Unlike simply normalizing the radius,
// it also redistributes angle: grains from crowded corners move toward the
// short-side sectors as the population rounds out. The center remains fixed.
vec2 sand_disk(vec2 point, vec2 half_size) {
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
vec2 sand_rectangle_ray(float angle, vec2 half_size) {
    vec2 edge = angle <= 0.78539816 ? vec2(1.0, angle / 0.78539816)
                                  : vec2((1.57079633 - angle) / 0.78539816, 1.0);
    return 2.0 * half_size * edge;
}

// Invert the evolving transport once per pixel. It is monotonic in angle, so
// bisection avoids folds and also lets the gather find laterally moving grains.
vec2 sand_flow_query(vec2 point, vec2 half_size, float spread) {
    vec2 a = abs(point);
    float lower = 0.0;
    float upper = 1.57079633;
    for (int i = 0; i < 12; i++) {
        float angle = 0.5 * (lower + upper);
        vec2 ray = mix(sand_rectangle_ray(angle, half_size), vec2(cos(angle), sin(angle)), spread);
        if (ray.y * a.x < ray.x * a.y)
            lower = angle;
        else
            upper = angle;
    }
    float angle = 0.5 * (lower + upper);
    vec2 direction = vec2(cos(angle), sin(angle));
    vec2 ray = mix(sand_rectangle_ray(angle, half_size), direction, spread);
    return direction * sign(point) * (length(point) / max(length(ray), 0.000001));
}

// A jittered polar lattice lets us find neighboring round grains even when
// suction strongly compresses their angular spacing near the inlet.
vec2 sand_cell(vec2 point, float cell_size) {
    float ring = floor(length(point) / cell_size);
    float count = max(floor(6.2831853 * (ring + 0.5)), 1.0);
    float angle = length(point) > 0.000001 ? mod(atan(point.y, point.x) + 6.2831853, 6.2831853) : 0.0;
    return vec2(ring, floor(angle * count / 6.2831853));
}

vec2 sand_origin(vec2 cell, float cell_size) {
    float count = max(floor(6.2831853 * (cell.x + 0.5)), 1.0);
    vec2 jitter = vec2(sand_hash(cell + vec2(19.2, 7.1)),
                       sand_hash(cell + vec2(3.7, 41.3))) - 0.5;
    float radius = (cell.x + 0.5 + jitter.x * 0.4) * cell_size;
    float angle = (cell.y + 0.5 + jitter.y * 0.4) * 6.2831853 / count;
    return vec2(cos(angle), sin(angle)) * radius;
}

float sand_response(float age) {
    age = max(age, 0.0);
    return max(age - 0.045 * (1.0 - exp(-age / 0.045)), 0.0);
}

float sand_response_inverse(float distance) {
    if (distance <= 0.000001)
        return sqrt(max(0.09 * distance, 0.0));
    float age = distance + 0.045;
    for (int i = 0; i < 6; i++) {
        float slope = max(1.0 - exp(-age / 0.045), 0.0001);
        age = max(age - (sand_response(age) - distance) / slope, 0.000001);
    }
    return age;
}

// Invert each friction class separately so delayed grains do not vanish merely
// because they move outside the neighborhood of an average-friction trajectory.
float sand_source_squared(float target_squared, float time, float friction,
                           float reach_squared, float strength, float material_scale_squared) {
    float original = target_squared + strength * sand_response(time);
    for (int i = 0; i < 6; i++) {
        float material_squared = original * material_scale_squared;
        float age = max(time - sand_release(material_squared, friction, reach_squared), 0.0);
        float residual = original - strength * sand_response(age) - target_squared;
        // Include the derivative of distance-dependent friction in the inverse.
        float release_slope = 0.18 * friction * material_scale_squared / reach_squared
                            * (0.25 + 0.5 * material_squared / reach_squared);
        float slope = 1.0 + strength * release_slope * (1.0 - exp(-age / 0.045));
        original = max(original - residual / slope, target_squared);
    }
    return original;
}

// Return screen radius, depth scale, and time since entrainment. Once a grain
// crosses the circular mouth it falls in depth: z proportional to dt^2, with
// pinhole scale 1/(1+z/f). Friction still uses actual material distance. Transport
// uses circularized flow distance so corners do not have a much longer drain time.
vec3 sand_motion(float original_squared, float flow_squared, float time, float friction,
                 float reach_squared, float strength, float mouth) {
    float age = max(time - sand_release(original_squared, friction, reach_squared), 0.0);
    float remaining = flow_squared - strength * sand_response(age);
    if (remaining >= mouth * mouth)
        return vec3(sqrt(remaining), 1.0, age);
    float capture_age = sand_response_inverse(max((flow_squared - mouth * mouth) / strength, 0.0));
    float fall_time = max(age - capture_age, 0.0);
    float depth_scale = 1.0 / (1.0 + 400.0 * fall_time * fall_time);
    return vec3(min(sqrt(flow_squared), mouth) * depth_scale, depth_scale, age);
}

float sand_outline(vec2 point, vec2 size_geo, float corner) {
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
    float pixel = 1.0 / short_side;
    float corner = min(28.0, short_side * 0.5);
    float reach = length(aspect * 0.5);
    float reach_squared = reach * reach;
    float cell_size = clamp(short_side / 180.0, 3.0, 7.0) * pixel;
    float mouth = 0.01625;
    float formation = smoothstep(0.0, 0.10, time);
    float collapse = 1.0 - smoothstep(0.90, 1.0, time);
    float horizon = mouth * formation * collapse;
    // Delay spreading until all grains have begun releasing. Then allow motion
    // across rays, continuously rounding the population before the late drain.
    float spread = smoothstep(0.12, 0.42, time);
    // Keep the depth-entry radius inside the visible circular mouth at every
    // stage of the rectangle-to-disk transition, including ultrawide windows.
    float flow_mouth = mouth / length(aspect);
    // Even the highest-friction grain at the farthest corner reaches the inlet
    // by 80%, leaving time to recede into the well before the rim closes.
    float strength = (0.25 - flow_mouth * flow_mouth) / sand_response(0.80 - 0.18 * 1.15);

    vec2 base_cell = sand_cell(point, cell_size);
    float base_group = floor(sand_hash(base_cell) * 5.0);
    vec2 base_center = sand_origin(base_cell, cell_size);
    float base_friction = 0.85 + 0.075 * base_group;
    float base_age = max(time - sand_release(dot(base_center, base_center), base_friction, reach_squared), 0.0);
    float detach = smoothstep(0.0, 0.025, base_age);
    float base_coverage = 1.0 - smoothstep(-1.0, 1.0, sand_outline(point * short_side, size_geo.xy, corner));
    vec4 color = vec4(0.0);
    if (detach < 1.0 && coords_geo.x >= 0.0 && coords_geo.x <= 1.0
            && coords_geo.y >= 0.0 && coords_geo.y <= 1.0) {
        // Undisturbed grains retain the original image until their own friction
        // threshold is crossed. Never draw a stretched continuous window.
        color = texture2D(niri_tex, (niri_geo_to_tex * coords_geo).st) * base_coverage * (1.0 - detach);
    }
    float shadow = (1.0 - smoothstep(max(0.0, horizon - pixel), horizon + pixel, radius))
                 * formation * collapse;
    color = vec4(vec3(0.0), shadow) + color * (1.0 - shadow);

    vec2 flow_point = sand_flow_query(point, half_size, spread);
    float flow_radius = length(flow_point);
    float flow_angle = flow_radius > 0.000001 ? atan(abs(flow_point.y), abs(flow_point.x)) : 0.0;
    vec2 material_ray = sand_rectangle_ray(flow_angle, half_size) * sign(point);
    float material_scale_squared = dot(material_ray, material_ray);
    float query_angle = radius > 0.000001 ? mod(atan(material_ray.y, material_ray.x) + 6.2831853, 6.2831853) : 0.0;
    float query_time = time;
    float target_squared = flow_radius * flow_radius;
    if (flow_radius < flow_mouth) {
        // Backtrace the perspective descent to the time of crossing the mouth.
        query_time -= sqrt(max(flow_mouth / max(flow_radius, pixel * 0.05) - 1.0, 0.0) / 400.0);
        target_squared = flow_mouth * flow_mouth;
    }
    if (query_time >= 0.0 && radius <= reach + cell_size) {
        for (int group = 0; group < 5; group++) {
            float friction = 0.85 + 0.075 * float(group);
            float source_squared = sand_source_squared(target_squared, query_time, friction,
                                                        reach_squared, strength, material_scale_squared)
                                 * material_scale_squared;
            if (source_squared > (reach + cell_size) * (reach + cell_size))
                continue;
            float source_ring = floor(sqrt(source_squared) / cell_size);
            // Compression in wide windows can bring a few extra source rings
            // within one grain's footprint; include them to avoid clipped grains.
            float ring_search = min(4.0, ceil(length(aspect) * 0.5));
            for (int y = -4; y <= 4; y++) {
                if (abs(float(y)) > ring_search)
                    continue;
                float ring = source_ring + float(y);
                if (ring < 0.0)
                    continue;
                float count = max(floor(6.2831853 * (ring + 0.5)), 1.0);
                float sector = floor(query_angle * count / 6.2831853);
                for (int x = -1; x <= 1; x++) {
                    vec2 cell = vec2(ring, mod(sector + float(x) + count, count));
                    if (floor(sand_hash(cell) * 5.0) != float(group))
                        continue;
                    vec2 original_point = sand_origin(cell, cell_size);
                    float original_radius = length(original_point);
                    if (original_radius <= mouth)
                        continue;
                    vec2 source = original_point / aspect + 0.5;
                    if (source.x < 0.0 || source.x > 1.0 || source.y < 0.0 || source.y > 1.0
                            || sand_outline(original_point * short_side, size_geo.xy, corner) > 0.0)
                        continue;
                    vec2 original_flow = sand_disk(original_point, half_size);
                    float flow_squared = dot(original_flow, original_flow);
                    vec3 motion = sand_motion(original_radius * original_radius, flow_squared, time, friction,
                                              reach_squared, strength, flow_mouth);
                    vec2 grain_center = mix(original_point, original_flow, spread)
                                      * (motion.x / max(sqrt(flow_squared), 0.000001));
                    // Keep real grain size until the inlet, then shrink only
                    // with perspective depth. Never stretch a texture cell.
                    float grain_radius = cell_size * (0.37 + 0.08 * sand_hash(cell + 13.7))
                                       * motion.y;
                    float resolved_radius = max(grain_radius, pixel * 0.4);
                    float grain_coverage = 1.0 - smoothstep(max(resolved_radius - pixel * 0.5, 0.0),
                                                          resolved_radius + pixel * 0.5, length(point - grain_center));
                    grain_coverage *= min(1.0, (grain_radius * grain_radius) / (resolved_radius * resolved_radius));
                    grain_coverage *= smoothstep(0.0, 0.025, motion.z) * collapse;
                    if (grain_coverage <= 0.0)
                        continue;
                    vec4 grain = texture2D(niri_tex, (niri_geo_to_tex * vec3(source, 1.0)).st);
                    grain.rgb *= (0.85 + 0.15 * sand_hash(cell + 31.1)) * mix(0.45, 1.0, motion.y);
                    grain *= grain_coverage;
                    color = grain + color * (1.0 - grain.a);
                }
            }
        }
    }

    float ring_radius = horizon * 1.12;
    float ring_distance = abs(radius - ring_radius);
    float width = max(0.000625 * collapse, pixel * 0.5);
    float rim = 1.0 - smoothstep(width, width + pixel, ring_distance);
    float glow = exp(-pow(ring_distance / max(0.003 * collapse, pixel), 2.0));
    float light_alpha = clamp(0.85 * rim + 0.22 * glow, 0.0, 1.0) * formation * collapse;
    vec3 light_color = mix(vec3(1.0, 0.55, 0.18), vec3(1.0, 0.94, 0.78), rim);
    return vec4(light_color * light_alpha, light_alpha) + color * (1.0 - light_alpha);
}
