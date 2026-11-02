#version 300 es
precision highp float;
uniform sampler2D wallpaper;
uniform vec2 resolution;
uniform vec2 image_size;
uniform float progress;
out vec4 frag_color;

void main() {
    // Match Noctalia's centered crop and PIL's top-to-bottom image rows.
    vec2 uv = vec2(gl_FragCoord.x / resolution.x, 1.0 - gl_FragCoord.y / resolution.y);
    float screen_aspect = resolution.x / resolution.y;
    float image_aspect = image_size.x / image_size.y;
    vec2 crop = vec2(min(1.0, screen_aspect / image_aspect),
                     min(1.0, image_aspect / screen_aspect));
    vec2 scale = resolution / min(resolution.x, resolution.y);
    vec2 p = (uv - 0.5) * scale;
    float radius = length(p);
    vec2 radial = p / max(radius, 0.001);
    float time = progress * 1.4;

    // A drop depresses the center, rebounds, then sends a damped wave train out.
    // Reach the corners on wide and portrait monitors without stretching circles.
    float reach = length(scale * 0.5);
    float front = time * (reach + 0.18) / 1.25;
    float behind = front - radius;
    float packet = smoothstep(-0.04, 0.025, behind)
                 * exp(-max(behind, 0.0) * 8.0);
    float wave = sin(behind * 68.0) * packet * exp(-1.4 * time);
    float impact = sin(time * 23.0) * exp(-time * 10.0)
                 * exp(-radius * radius * 160.0);
    float envelope = smoothstep(0.0, 0.045, progress)
                   * (1.0 - smoothstep(0.72, 1.0, progress));
    float edge = smoothstep(0.0, 0.06, uv.x) * smoothstep(0.0, 0.06, 1.0 - uv.x)
               * smoothstep(0.0, 0.06, uv.y) * smoothstep(0.0, 0.06, 1.0 - uv.y);
    float center = smoothstep(0.0, 0.035, radius);
    vec2 displacement = radial / scale * (0.025 * wave + 0.045 * impact)
                      * envelope * edge * center;
    vec3 color = texture(wallpaper, (uv - displacement - 0.5) * crop + 0.5).rgb;

    // Subtle crest lighting keeps the water visible against dark wallpapers.
    float crest = cos(behind * 68.0) * packet * exp(-1.8 * time);
    float lighting = crest * envelope * edge * center;
    color = color * (1.0 + 0.10 * lighting)
          + vec3(0.55, 0.75, 0.85) * max(lighting, 0.0) * 0.045;
    float alpha = smoothstep(0.0, 0.025, progress)
                * (1.0 - smoothstep(0.94, 1.0, progress));
    frag_color = vec4(color * alpha, alpha);
}
