#version 300 es
precision highp float;
uniform sampler2D wallpaper;
uniform vec2 resolution;
uniform vec2 image_size;
uniform float progress;
out vec4 frag_color;

void main() {
    vec2 uv = vec2(gl_FragCoord.x / resolution.x, 1.0 - gl_FragCoord.y / resolution.y);
    vec2 scale = resolution / min(resolution.x, resolution.y);
    vec2 p = (uv - 0.5) * scale;
    float radius = length(p);
    vec2 radial = p / max(radius, 0.0001);

    // Keep the pulse circular and carry it all the way to the monitor corners.
    float reach = length(scale * 0.5);
    float front = 0.025 + (reach + 0.10) * progress;
    float width = 0.055 + 0.035 * progress;
    float distance = (radius - front) / width;
    float packet = exp(-distance * distance);
    float wave = distance * packet;
    float dent = exp(-radius * radius / 0.006) * exp(-progress * 12.0);
    float envelope = smoothstep(0.0, 0.08, progress)
                   * (1.0 - smoothstep(0.80, 1.0, progress));
    vec2 displacement = radial / scale * (0.16 * wave - 0.055 * dent)
                      * envelope * smoothstep(0.0, 0.008, radius);

    float screen_aspect = resolution.x / resolution.y;
    float image_aspect = image_size.x / image_size.y;
    vec2 crop = vec2(min(1.0, screen_aspect / image_aspect),
                     min(1.0, image_aspect / screen_aspect));
    vec3 color = texture(wallpaper, (uv - displacement - 0.5) * crop + 0.5).rgb;
    // No tint or crest lighting. Only the moving pulse covers live pixels.
    float alpha = clamp(packet * 1.8 + dent, 0.0, 1.0) * envelope * 0.92;
    frag_color = vec4(color * alpha, alpha);
}
