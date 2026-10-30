#version 300 es
precision highp float;

uniform vec2 resolution;
uniform float progress;
out vec4 fragColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x),
               mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p = mat2(1.6, -1.2, 1.2, 1.6) * p + 3.7;
        amplitude *= 0.5;
    }
    return value;
}

// GTK composites premultiplied alpha. Keep the rest of the desktop transparent.
vec4 light(vec3 color, float alpha, vec2 uv) {
    float envelope = smoothstep(0.0, 0.16, progress)
                   * (1.0 - smoothstep(0.45, 1.0, progress));
    float edge = smoothstep(0.0, 0.025, uv.x)
               * (1.0 - smoothstep(0.975, 1.0, uv.x))
               * (1.0 - smoothstep(0.97, 1.0, uv.y));
    alpha = clamp(alpha * envelope * edge, 0.0, 0.88);
    return vec4(color * alpha, alpha);
}
