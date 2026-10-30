// Flowing curtains at multiple heights sweep across the whole monitor.
void main() {
    vec2 uv = gl_FragCoord.xy / resolution;
    float time = progress * 1.5;
    vec3 radiance = vec3(0);
    float density = 0.0;
    for (int i = 0; i < 4; i++) {
        float layer = float(i);
        float wave = 0.08 + 0.23 * layer
                   + 0.09 * sin(uv.x * 9.0 + time + layer * 1.8)
                   + 0.045 * sin(uv.x * 21.0 - time * 1.4 + layer);
        float d = uv.y - wave;
        float ribbon = exp(-d * d * 550.0);
        float curtain = exp(-max(d, 0.0) * 5.0) * smoothstep(-0.04, 0.03, d);
        float filaments = 0.35 + 0.65 * noise(vec2(uv.x * 180.0 + time * 5.0, layer * 7.0));
        float glow = ribbon * 0.5 + curtain * filaments * 0.7;
        vec3 color = mix(vec3(0.12, 1.0, 0.72), vec3(0.64, 0.3, 1.0),
                         0.5 + 0.5 * sin(uv.x * 5.0 + layer * 1.8 + time * 0.4));
        radiance += color * glow;
        density += glow;
    }
    fragColor = light(radiance / max(density, 0.001), density * 0.95, uv);
}
