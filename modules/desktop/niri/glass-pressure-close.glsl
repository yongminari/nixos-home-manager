// A meteor hits from behind the glass and continues toward the viewer (-z).
// Fade to glass, approach, contact deformation, cracks, then ballistic shards.
// Jittered hexagonal Voronoi cells form a few dozen large glass prisms.
// Each prism keeps the bent window texture and has actual shaded side faces.
// Times are seconds; the Niri duration must match GLASS_DURATION.
const float GLASS_DURATION = 1.7;
const float METEOR_START = 0.16;
const float METEOR_IMPACT = 1.22;
const float METEOR_STRAIGHT_START = METEOR_IMPACT - 0.12;
const float GLASS_CRACK_START = (METEOR_IMPACT + 0.02) / GLASS_DURATION;
const float GLASS_CRACK_END = (METEOR_IMPACT + 0.08) / GLASS_DURATION;
const float GLASS_BREAK = (METEOR_IMPACT + 0.095) / GLASS_DURATION;
const float GLASS_POWDER_LIFE = 0.16 / GLASS_DURATION;
const float GLASS_CAMERA_DISTANCE = 1.8;
// The virtual pane's short side represents 2.4 metres, independent of pixels.
const float GLASS_GRAVITY = 9.81 / 2.4;
// Apparent diameter at contact, relative to the window's short side.
const float METEOR_CONTACT_DIAMETER = 0.125;
// Scale the exponent with flight time to preserve the original impact speed
// (power / duration), while spending the extra 0.5 seconds on a slower approach.
const float METEOR_APPROACH_POWER = 2.2 * (METEOR_IMPACT - METEOR_START) / 0.56;
const float METEOR_SPIN_RATE = 17.0; // Ten times the original 1.7 rad/s.

mat3 glass_meteor_rotation(float seconds) {
    // A tilted principal spin plus a small, slower wobble. Share this frame
    // between the silhouette, crater relief, material grain, and hot patches.
    vec3 axis = normalize(vec3(0.45, 0.78, 0.44));
    float spin = seconds * METEOR_SPIN_RATE;
    float c = cos(spin);
    float s = sin(spin);
    float k = 1.0 - c;
    mat3 rotation = mat3(
        c + axis.x * axis.x * k, axis.y * axis.x * k + axis.z * s, axis.z * axis.x * k - axis.y * s,
        axis.x * axis.y * k - axis.z * s, c + axis.y * axis.y * k, axis.z * axis.y * k + axis.x * s,
        axis.x * axis.z * k + axis.y * s, axis.y * axis.z * k - axis.x * s, c + axis.z * axis.z * k);
    float wobble = 0.20 * sin(seconds * 5.2);
    float cw = cos(wobble);
    float sw = sin(wobble);
    return mat3(1.0, 0.0, 0.0, 0.0, cw, sw, 0.0, -sw, cw) * rotation;
}

float glass_meteor_shape(vec3 direction) {
    // A fixed, slightly elongated and lumpy body. Rotation changes which part
    // of this same 3D shape appears at the rim; it no longer wiggles separately.
    return 0.935 + 0.035 * (direction.x * direction.x - direction.y * direction.y)
                 + 0.020 * sin(direction.z * 4.0 + direction.x * 3.0)
                 + 0.010 * sin(direction.y * 7.0 - direction.z * 2.0);
}

float glass_meteor_radius() {
    float r = METEOR_CONTACT_DIAMETER * 0.5;
    return r * GLASS_CAMERA_DISTANCE / sqrt(GLASS_CAMERA_DISTANCE * GLASS_CAMERA_DISTANCE + r * r);
}

float glass_impact_speed(float pixel) {
    float r = METEOR_CONTACT_DIAMETER * 0.5;
    float start = min(pixel * 0.5, r * 0.5);
    float projected_speed = METEOR_APPROACH_POWER * (r - start) / (METEOR_IMPACT - METEOR_START);
    float radius = glass_meteor_radius();
    // Exact derivative of sphere depth with respect to apparent radius at impact.
    return GLASS_CAMERA_DISTANCE * radius * radius / (r * r * r) * projected_speed;
}

float glass_meteor_depth(float seconds, float pixel) {
    if (seconds >= METEOR_IMPACT)
        return GLASS_CAMERA_DISTANCE - glass_impact_speed(pixel) * (seconds - METEOR_IMPACT);
    float r = METEOR_CONTACT_DIAMETER * 0.5;
    float start = min(pixel * 0.5, r * 0.5);
    float approach = clamp((seconds - METEOR_START) / (METEOR_IMPACT - METEOR_START), 0.0, 1.0);
    // Apparent growth accelerates; continue its depth velocity through impact
    // without the previous sudden braking. Flight after impact is constant-speed.
    float projected = mix(start, r, pow(approach, METEOR_APPROACH_POWER));
    return glass_meteor_radius() * sqrt(1.0 + pow(GLASS_CAMERA_DISTANCE / projected, 2.0));
}

vec2 glass_meteor_offset(float seconds) {
    // Tilt the rounded L by 25 degrees so its final leg also descends from
    // the upper left, instead of approaching the axis horizontally.
    // Overlap the two legs to round the corner without dipping below center.
    // Quintic easing gives zero lateral velocity and acceleration at the join.
    float t = clamp((seconds - METEOR_START) / (METEOR_STRAIGHT_START - METEOR_START), 0.0, 1.0);
    vec2 travel = clamp(vec2((t - 0.30) / 0.70, t / 0.70), 0.0, 1.0);
    vec2 eased = travel * travel * travel * (travel * (travel * 6.0 - 15.0) + 10.0);
    vec2 offset = vec2(-0.38, -0.32) * (vec2(1.0) - eased);
    return vec2(0.9063078 * offset.x - 0.4226183 * offset.y,
                0.4226183 * offset.x + 0.9063078 * offset.y);
}

float glass_pressure(float seconds, float pixel) {
    // Deformation starts at contact, driven by the projectile's penetration.
    // This is a prescribed deformation, not a fracture/impact mechanics solver.
    float penetration = max(0.0, glass_impact_speed(pixel) * (seconds - METEOR_IMPACT));
    return clamp(penetration / 0.45, 0.0, 1.0);
}

float glass_rock_noise(vec3 p) {
    vec3 cell = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float n = dot(cell, vec3(1.0, 57.0, 113.0));
    vec4 lower = fract(sin(vec4(n, n + 1.0, n + 57.0, n + 58.0)) * 43758.5453);
    vec4 upper = fract(sin(vec4(n + 113.0, n + 114.0, n + 170.0, n + 171.0)) * 43758.5453);
    return mix(mix(mix(lower.x, lower.y, f.x), mix(lower.z, lower.w, f.x), f.y),
               mix(mix(upper.x, upper.y, f.x), mix(upper.z, upper.w, f.x), f.y), f.z);
}

vec3 glass_meteor_rock(vec3 surface, float detail, mat3 rotation) {
    surface = rotation * surface;
    // Crater bowls and raised rims live on the sphere, not in screen space.
    vec3 gradient = vec3(0.0);
    float height = 0.0;
    if (detail > 0.001) {
        for (int i = 0; i < 32; i++) {
            float index = float(i) + 0.5;
            float latitude = 1.0 - 2.0 * index / 32.0;
            float ring = sqrt(max(0.0, 1.0 - latitude * latitude));
            float angle = index * 2.39996323;
            vec3 center = vec3(ring * cos(angle), ring * sin(angle), latitude);
            float random = fract(sin(index * 91.37) * 118.3);
            float radius = mix(0.085, 0.30, random);
            vec3 delta = surface - center;
            float distance = max(length(delta), 0.0001);
            float q = distance / radius;
            if (q > 1.5) continue;
            float bowl = max(0.0, 1.0 - q * q);
            float rim = exp(-pow((q - 1.0) / 0.15, 2.0));
            height += radius * (-0.16 * bowl * bowl + 0.055 * rim);
            float slope = 0.64 * q * bowl - 0.11 * (q - 1.0) * rim / (0.15 * 0.15);
            gradient += delta / distance * slope;
        }
    }
    // Project the height gradient onto the tangent plane for bump lighting.
    gradient -= surface * dot(gradient, surface);
    vec3 normal = normalize(surface - gradient * detail);
    normal = vec3(dot(rotation[0], normal), dot(rotation[1], normal), dot(rotation[2], normal));
    vec3 light = normalize(vec3(-0.55, -0.65, -0.70));
    float diffuse = max(0.0, dot(normal, light));
    float grain = glass_rock_noise(surface * 110.0) - 0.5;
    float mottling = glass_rock_noise(surface * 17.0) - 0.5;
    float albedo = clamp(0.58 + height * 2.6 * detail
                       + (0.045 * grain + 0.10 * mottling) * detail, 0.24, 0.76);
    // Matte grey rock, with dark crater floors and illuminated raised rims.
    return vec3(1.0, 0.98, 0.94) * albedo * (0.16 + 0.84 * diffuse);
}

vec4 glass_meteor(vec2 point, float seconds, float pixel) {
    if (seconds < METEOR_START) return vec4(0.0);
    float focal = GLASS_CAMERA_DISTANCE;
    float radius = glass_meteor_radius();
    float depth = glass_meteor_depth(seconds, pixel);
    // Do not fade in front of the lens: the camera enters the sphere, sees it
    // fill the whole viewport, then exits its rear surface as it keeps moving.
    if (depth <= -radius) return vec4(0.0);
    float coverage = 1.0;
    float detail = 1.0;
    vec4 fire = vec4(0.0);
    float angular = length(point) > pixel * 0.01 ? atan(point.y, point.x) : 0.0;
    mat3 rotation = glass_meteor_rotation(seconds);
    float shape = glass_meteor_shape(rotation * vec3(cos(angular), sin(angular), 0.0));
    vec2 rock_point = point / shape;
    if (depth > radius) {
        float projected_radius = focal * radius / sqrt(depth * depth - radius * radius);
        float distance = length(point);
        float q = distance / max(projected_radius, pixel * 0.5);
        if (q > 2.1 + pixel / projected_radius) return vec4(0.0);
        float turbulence = glass_rock_noise(vec3(cos(angular) * 9.0, sin(angular) * 9.0,
                                                 seconds * 27.0 - q * 8.0));
        float flame_length = 0.12 + 0.55 * turbulence * turbulence;
        float outside = max(0.0, q - shape);
        float flame = exp(-outside * 5.0 / flame_length)
                    * (1.0 - smoothstep(shape + flame_length, shape + flame_length + 0.15, q));
        float bloom = exp(-outside * outside / 0.12) * 0.14;
        float heat = smoothstep(2.0, 14.0, projected_radius / pixel);
        float alpha = clamp(flame * 0.86 + bloom, 0.0, 0.96) * heat;
        vec3 hot = mix(vec3(1.0, 0.13, 0.015), vec3(1.0, 0.87, 0.35), flame);
        fire = vec4(hot * alpha, alpha);
        coverage = 1.0 - smoothstep(max(0.0, projected_radius * shape - pixel * 0.5),
                                    projected_radius * shape + pixel * 0.5, distance);
        detail = smoothstep(5.0, 28.0, projected_radius / pixel);
        if (coverage <= 0.0) return fire;
    }
    vec3 ray = normalize(vec3(rock_point, focal));
    float b = depth * ray.z;
    float discriminant = max(0.0, radius * radius - depth * depth * (1.0 - ray.z * ray.z));
    float root = sqrt(discriminant);
    float hit = b - root;
    if (hit < 0.0) hit = b + root;
    vec3 surface = normalize(ray * hit - vec3(0.0, 0.0, depth));
    vec3 rock = glass_meteor_rock(surface, detail, rotation);
    // Keep crater relief visible; incandescent edges and sparse hot patches
    // provide heat without replacing the entire rock with a flat fireball.
    float hot_edge = pow(1.0 - abs(surface.z), 2.5) * detail;
    float hot_spots = smoothstep(0.68, 0.90, glass_rock_noise((rotation * surface) * 19.0)) * 0.28 * detail;
    rock = mix(rock, vec3(1.0, 0.39, 0.045), clamp(hot_edge * 0.85 + hot_spots, 0.0, 0.9));
    return vec4(rock * coverage, coverage) + fire * (1.0 - coverage);
}

vec2 glass_hash(vec2 p) {
    p += niri_random_seed * vec2(71.3, 113.7);
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)),
                          dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

vec2 glass_site(vec2 id) {
    return vec2(id.x + 0.5 * mod(id.y, 2.0), id.y * 0.8660254)
         + (glass_hash(id) - 0.5) * 0.32;
}

vec2 glass_neighbor(vec2 id, int edge) {
    float diagonal = mod(id.y, 2.0) - 1.0;
    if (edge == 0) return id + vec2(-1.0, 0.0);
    if (edge == 1) return id + vec2(1.0, 0.0);
    if (edge == 2) return id + vec2(diagonal, -1.0);
    if (edge == 3) return id + vec2(diagonal + 1.0, -1.0);
    if (edge == 4) return id + vec2(diagonal, 1.0);
    return id + vec2(diagonal + 1.0, 1.0);
}

vec2 glass_grid(vec2 p) {
    float row = floor(p.y / 0.8660254 + 0.5);
    return vec2(floor(p.x - 0.5 * mod(row, 2.0) + 0.5), row);
}

vec2 glass_unbend(vec2 point, float pressure) {
    // Invert perspective magnification from a smooth central bulge toward -z.
    vec2 source = point;
    for (int i = 0; i < 7; i++) {
        float depth = 1.0 - 0.22 * pressure * exp(-7.5 * dot(source, source));
        source = point * depth;
    }
    return source;
}

vec4 glass_window(vec2 point, vec2 size, float pressure, float aa) {
    float short_side = max(min(size.x, size.y), 1.0);
    vec2 source = glass_unbend(point, pressure) * short_side / size + 0.5;
    if (source.x < 0.0 || source.x > 1.0 || source.y < 0.0 || source.y > 1.0)
        return vec4(0.0);
    float corner = min(28.0, short_side * 0.5);
    vec2 q = abs((source - 0.5) * size) - (size * 0.5 - vec2(corner));
    float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - corner;
    float coverage = 1.0 - smoothstep(-aa, aa, distance);
    return texture2D(niri_tex, (niri_geo_to_tex * vec3(source, 1.0)).st) * coverage;
}

float glass_edge(vec2 local, vec2 id, vec2 site) {
    float distance = 10.0;
    for (int edge = 0; edge < 6; edge++) {
        vec2 delta = glass_site(glass_neighbor(id, edge)) - site;
        float len = length(delta);
        distance = min(distance, 0.5 * len - dot(local, delta / len));
    }
    return distance;
}

vec4 glass_nearest(vec2 point) {
    vec2 grid = glass_grid(point);
    float best = 100.0;
    vec4 nearest = vec4(0.0);
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 id = grid + vec2(float(x), float(y));
            vec2 site = glass_site(id);
            float distance = dot(point - site, point - site);
            if (distance < best) { best = distance; nearest = vec4(site, id); }
        }
    }
    return nearest;
}

vec4 glass_coating(vec4 picture, float rim, float crack, float opacity) {
    // Premultiplied-alpha glass: the surface is 50% opaque, while white
    // fractures scatter more light and remain clear against the desktop.
    float white = picture.a * max(0.18 * rim, 0.92 * crack);
    return vec4(vec3(white), white) + picture * opacity * (1.0 - white);
}

vec4 glass_powder(vec2 point, vec2 size, float cell, vec4 nearest, float p, float aa) {
    float short_side = min(size.x, size.y);
    float cell_pixels = short_side * cell;
    float reach = 0.5 * length(size / short_side) + cell;
    vec2 site = nearest.xy;
    vec2 id = nearest.zw;
    vec4 powder = vec4(0.0);
    for (int edge = 0; edge < 6; edge++) {
        vec2 neighbor_id = glass_neighbor(id, edge);
        vec2 neighbor = glass_site(neighbor_id);
        vec2 middle = 0.5 * (site + neighbor);
        vec2 normal = normalize(neighbor - site);
        // Canonical orientation makes both sides emit the same particles.
        if (normal.x < 0.0 || (normal.x == 0.0 && normal.y < 0.0)) normal = -normal;
        vec2 tangent = vec2(-normal.y, normal.x);
        if (abs(dot(point - middle, normal)) * cell_pixels > 44.0) continue;
        for (int grain = 0; grain < 3; grain++) {
            vec2 random = glass_hash(id + neighbor_id + vec2(float(grain) * 17.3, 51.9));
            vec2 emitter = middle + tangent * ((random.x - 0.5) * 0.52);
            if (glass_edge(emitter - site, id, site) < -0.0001) continue;
            float radius = clamp(length(emitter * cell) / reach, 0.0, 1.0);
            // Inverse smoothstep: emit exactly when the radial crack front arrives.
            float arrival = 0.5 - sin(asin(1.0 - 2.0 * radius) / 3.0);
            float birth = mix(GLASS_CRACK_START, GLASS_CRACK_END, arrival);
            float age = (p - birth) / GLASS_POWDER_LIFE;
            if (age <= 0.0 || age >= 1.0) continue;
            vec2 velocity = normalize(emitter + vec2(0.0001)) * (10.0 + 14.0 * random.y)
                          + (glass_hash(random + 7.4) - 0.5) * 20.0;
            vec2 center = emitter + (velocity * age + vec2(0.0, 4.0 * age * age)) / cell_pixels;
            float distance = length(point - center) * cell_pixels;
            float grain_radius = mix(0.7, 1.7, random.y) * (1.0 + 0.6 * age);
            if (distance > grain_radius * 3.0 + aa) continue;
            float fleck = 1.0 - smoothstep(grain_radius * 0.3, grain_radius + aa, distance);
            float haze = 0.06 * exp(-distance * distance / (4.0 * grain_radius * grain_radius));
            float alpha = min(1.0, fleck + haze) * 0.70
                        * smoothstep(0.0, 0.08, age) * (1.0 - age) * (1.0 - age);
            alpha *= glass_window(emitter * cell, size, 1.0, aa).a;
            powder = vec4(vec3(alpha), alpha) + powder * (1.0 - alpha);
        }
    }
    return powder;
}

mat3 glass_rotation(vec3 angles) {
    vec3 c = cos(angles);
    vec3 s = sin(angles);
    mat3 rx = mat3(1.0, 0.0, 0.0, 0.0, c.x, s.x, 0.0, -s.x, c.x);
    mat3 ry = mat3(c.y, 0.0, -s.y, 0.0, 1.0, 0.0, s.y, 0.0, c.y);
    mat3 rz = mat3(c.z, s.z, 0.0, -s.z, c.z, 0.0, 0.0, 0.0, 1.0);
    return rz * ry * rx;
}

bool glass_clip(vec3 origin, vec3 ray, vec3 normal, float limit,
                inout float near_hit, inout float far_hit, inout vec3 hit_normal) {
    float remaining = limit - dot(origin, normal);
    float slope = dot(ray, normal);
    if (abs(slope) < 0.00001)
        return remaining >= 0.0;
    float hit = remaining / slope;
    if (slope < 0.0) {
        if (hit > near_hit) {
            near_hit = hit;
            hit_normal = normal;
        }
    } else {
        far_hit = min(far_hit, hit);
    }
    return near_hit <= far_hit;
}

vec4 glass_scene(vec3 coords_geo, vec3 size_geo) {
    float p = clamp(niri_clamped_progress, 0.0, 1.0);
    if (p >= 1.0) return vec4(0.0);
    vec2 size = max(size_geo.xy, vec2(1.0));
    float short_side = min(size.x, size.y);
    vec2 aspect = size / short_side;
    vec2 point = (coords_geo.xy - 0.5) * aspect;
    float aa = 1.0 / max(niri_scale, 0.01);
    float seconds = p * GLASS_DURATION;
    float pressure = glass_pressure(seconds, aa / short_side);
    // About 30 large cells across the visible area, independent of resolution.
    float cell = sqrt(aspect.x * aspect.y / (30.0 * 0.8660254));
    float pixel = aa / (short_side * cell);
    vec2 grid_point = point / cell;
    vec4 nearest = vec4(0.0);
    vec4 powder = vec4(0.0);
    if (p < GLASS_CRACK_END + GLASS_POWDER_LIFE) {
        nearest = glass_nearest(grid_point);
        if (p > GLASS_CRACK_START)
            powder = glass_powder(grid_point, size, cell, nearest, p, aa);
    }

    if (p < GLASS_BREAK) {
        vec4 color = glass_window(point, size, pressure, aa);
        if (color.a <= 0.0) return powder;
        float edge = glass_edge(grid_point - nearest.xy, nearest.zw, nearest.xy);
        float crack_radius = smoothstep(GLASS_CRACK_START, GLASS_CRACK_END, p)
                           * (0.5 * length(aspect) + cell);
        float revealed = (1.0 - smoothstep(crack_radius - 0.05, crack_radius, length(point)))
                       * smoothstep(GLASS_CRACK_START, GLASS_CRACK_START + 0.025, p);
        float crack = (1.0 - smoothstep(0.4 * pixel, 1.8 * pixel, edge)) * revealed;
        float rim = (1.0 - smoothstep(1.8 * pixel, 3.3 * pixel, edge)) * revealed;
        float sheen = 0.055 * pressure * exp(-9.0 * dot(point, point));
        color.rgb = mix(color.rgb, vec3(0.75, 0.87, 0.94) * color.a, sheen);
        float opacity = mix(1.0, 0.5, smoothstep(0.0, 0.12, seconds));
        color = glass_coating(color, rim, crack, opacity);
        return powder + color * (1.0 - powder.a);
    }

    float elapsed = seconds - GLASS_BREAK * GLASS_DURATION;
    // Separated fragments retain their initial velocity. Gravity accelerates
    // them down (+y); no easing curve brakes their translational motion.
    float velocity_z = -glass_impact_speed(aa / short_side) * 0.85;
    float depth = 1.0 + velocity_z * elapsed / GLASS_CAMERA_DISTANCE;
    if (depth <= 0.08) return powder;
    float spread = 1.0 + 2.5 * elapsed;
    vec2 translation = vec2(0.0, 0.5 * GLASS_GRAVITY * elapsed * elapsed);
    // Negative-z travel reduces camera distance: pieces enlarge toward us.
    // Local prism rotation uses an orthographic ray; the common perspective
    // scale keeps the bounded neighborhood search stable for large fragments.
    vec2 projected = (point * depth - translation) / cell;
    vec2 grid = glass_grid(projected / spread);
    float closest = 100.0;
    vec4 color = vec4(0.0);
    float gap = 0.018 * smoothstep(0.0, 0.025, elapsed);
    float half_thickness = 0.035 * smoothstep(0.0, 0.02, elapsed);

    for (int y = -2; y <= 2; y++) {
        for (int x = -2; x <= 2; x++) {
            vec2 id = grid + vec2(float(x), float(y));
            vec2 site = glass_site(id);
            vec2 random = glass_hash(id + 43.7);
            vec2 drift = (random - 0.5) * 0.90 * elapsed;
            vec2 local_projected = projected - site * spread - drift;
            // A cell prism fits inside this circle at every rotation.
            if (dot(local_projected, local_projected) > 1.0) continue;
            // Constant angular rates approximate short torque-free flights.
            vec3 angles = vec3((random - 0.5) * 10.0,
                               (glass_hash(id + 92.3).x - 0.5) * 12.0) * elapsed;
            mat3 rotation = glass_rotation(angles);
            vec3 world_origin = vec3(local_projected, -2.0);
            vec3 origin = vec3(dot(rotation[0], world_origin),
                               dot(rotation[1], world_origin), dot(rotation[2], world_origin));
            vec3 ray = vec3(rotation[0].z, rotation[1].z, rotation[2].z);
            float near_hit = 0.0;
            float far_hit = 4.0;
            vec3 normal = vec3(0.0, 0.0, -1.0);
            bool hit = glass_clip(origin, ray, vec3(0.0, 0.0, -1.0), half_thickness,
                                  near_hit, far_hit, normal);
            if (hit) hit = glass_clip(origin, ray, vec3(0.0, 0.0, 1.0), half_thickness,
                                      near_hit, far_hit, normal);
            for (int edge = 0; edge < 6; edge++) {
                if (!hit) break;
                vec2 delta = glass_site(glass_neighbor(id, edge)) - site;
                float len = length(delta);
                hit = glass_clip(origin, ray, vec3(delta / len, 0.0), 0.5 * len - gap,
                                  near_hit, far_hit, normal);
            }
            if (!hit || near_hit >= closest) continue;
            vec3 position = origin + ray * near_hit;
            vec4 shard = glass_window((site + position.xy) * cell, size, 1.0,
                                      aa * depth);
            if (shard.a <= 0.0) continue;
            float edge = glass_edge(position.xy, id, site) - gap;
            float rim = 1.0 - smoothstep(1.8 * pixel * depth, 3.3 * pixel * depth, edge);
            float crack = 1.0 - smoothstep(0.4 * pixel * depth, 1.8 * pixel * depth, edge);
            vec3 world_normal = rotation * normal;
            float light = 0.65 + 0.35 * max(0.0, dot(world_normal, normalize(vec3(-0.4, -0.6, -1.0))));
            if (abs(normal.z) < 0.5) {
                // Blue-grey cut faces provide thickness without replacing the
                // original picture on the large front and rear surfaces.
                shard.rgb = mix(shard.rgb * 0.45, vec3(0.37, 0.58, 0.66) * shard.a, 0.72) * light;
                shard *= 0.5;
            } else {
                shard.rgb *= mix(1.0, light, smoothstep(0.0, 0.08, elapsed));
                shard = glass_coating(shard, rim, crack, 0.5);
            }
            color = shard;
            closest = near_hit;
        }
    }
    // Visibility changes only at the near clipping plane; velocity stays fixed.
    color *= smoothstep(0.08, 0.24, depth);
    return powder + color * (1.0 - powder.a);
}

vec4 close_color(vec3 coords_geo, vec3 size_geo) {
    float p = clamp(niri_clamped_progress, 0.0, 1.0);
    if (p >= 1.0) return vec4(0.0);
    vec2 size = max(size_geo.xy, vec2(1.0));
    float short_side = min(size.x, size.y);
    vec2 point = (coords_geo.xy - 0.5) * size / short_side;
    float seconds = p * GLASS_DURATION;
    float pixel = 1.0 / (short_side * max(niri_scale, 0.01));
    vec2 meteor_point = point - glass_meteor_offset(seconds);
    vec3 refracted = coords_geo;
    float depth = glass_meteor_depth(seconds, pixel);
    float radius = glass_meteor_radius();
    if (seconds >= METEOR_START && depth > radius) {
        float projected_radius = GLASS_CAMERA_DISTANCE * radius / sqrt(depth * depth - radius * radius);
        float q = length(meteor_point) / max(projected_radius, pixel);
        float heat_band = smoothstep(1.0, 1.15, q) * (1.0 - smoothstep(1.5, 1.9, q))
                        * smoothstep(8.0, 40.0, projected_radius / pixel);
        // Refract the available window image in a thin, moving hot-air layer.
        float angular = length(meteor_point) > pixel * 0.01 ? atan(meteor_point.y, meteor_point.x) : 0.0;
        float wave = sin(angular * 17.0 - seconds * 53.0 + q * 19.0);
        vec2 offset = meteor_point / max(length(meteor_point), pixel) * (2.0 * pixel * heat_band * wave);
        refracted.xy += offset * short_side / size;
    }
    vec4 pane = glass_scene(refracted, size_geo);
    vec4 meteor = glass_meteor(meteor_point, seconds, pixel);
    // Before contact it shines through the transparent glass; after contact
    // it crosses in front, continuing all the way toward the camera.
    return seconds < METEOR_IMPACT ? pane + meteor * (1.0 - pane.a)
                                  : meteor + pane * (1.0 - meteor.a);
}
