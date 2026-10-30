// Moving noise stretches into rising tongues with gold cores and ember tips.
void main() {
    vec2 uv = gl_FragCoord.xy / resolution;
    vec2 p = vec2(uv.x * resolution.x / resolution.y, uv.y);
    float time = progress * 2.8;
    float turbulence = fbm(vec2(p.x * 5.0, p.y * 3.0 - time * 2.0));
    float tongues = fbm(vec2(p.x * 9.0 + turbulence, p.y * 2.0 - time));
    float rise = smoothstep(0.0, 0.32, progress);
    float height = (0.35 + tongues * 0.95) * (0.15 + 1.3 * rise);
    float flame = 1.0 - smoothstep(height - 0.16, height + 0.08, uv.y);
    float heat = clamp((height - uv.y) * 2.5, 0.0, 1.0);
    vec3 color = mix(vec3(1.0, 0.12, 0.025), vec3(1.0, 0.68, 0.12), heat);
    color = mix(color, vec3(1.0, 0.92, 0.56), pow(heat, 4.0));
    float sparks = 0.0;
    for (int i = 0; i < 12; i++) {
        float seed = float(i);
        vec2 center = vec2(hash(vec2(seed, 2.0)) * resolution.x / resolution.y,
                           fract(hash(vec2(seed, 8.0)) + progress * 0.7));
        center.x += 0.035 * sin(time * 3.0 + seed);
        vec2 d = (p - center) * vec2(1.0, 0.45);
        sparks += exp(-dot(d, d) * 16000.0) * (1.0 - center.y);
    }
    fragColor = light(mix(color, vec3(1.0, 0.8, 0.3), clamp(sparks, 0.0, 1.0)),
                      flame * 0.82 + sparks * 0.7, uv);
}
