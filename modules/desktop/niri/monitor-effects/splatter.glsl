// Pools of colored light burst from the center and spread across the monitor.
void main() {
    vec2 uv = gl_FragCoord.xy / resolution;
    float aspect = resolution.x / resolution.y;
    vec2 p = (uv - 0.5) * vec2(aspect, 1.0);
    float time = progress * 1.6;
    float spread = smoothstep(0.0, 0.55, progress);
    vec3 paint = vec3(0);
    float density = 0.0;
    float grain = fbm(p * 9.0 - vec2(0, time));
    for (int i = 0; i < 9; i++) {
        float seed = float(i);
        float direction = seed * 2.39996;
        float orbit = i == 0 ? 0.0 : (0.12 + 0.26 * spread);
        vec2 center = vec2(cos(direction) * aspect, sin(direction)) * orbit;
        vec2 delta = p - center;
        float angle = atan(delta.y, delta.x);
        float radius = (0.38 + 0.1 * sin(seed * 4.1 + 1.0))
                     * (0.35 + 0.9 * spread);
        float lobes = 1.0 + 0.18 * sin(angle * 5.0 + seed * 3.0)
                          + 0.12 * sin(angle * 9.0 - time);
        float distance = length(delta * vec2(0.85, 1.0)) / (radius * lobes);
        float cloud = exp(-distance * distance * 2.0) * (0.4 + grain);
        vec3 color = 0.58 + 0.42 * cos(vec3(0.0, 2.0, 4.0) + seed * 1.7 + time * 0.3);
        paint += color * cloud;
        density += cloud;
        // Small detached flecks soften the boundary of each pool.
        vec2 fleck = delta - vec2(cos(direction), sin(direction)) * (0.2 + spread * 0.22);
        float spark = exp(-dot(fleck, fleck) * 950.0);
        paint += color * spark;
        density += spark;
    }
    fragColor = light(paint / max(density, 0.001), density * 0.95, uv);
}
