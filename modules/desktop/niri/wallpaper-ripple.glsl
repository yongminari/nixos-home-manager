#version 300 es
precision highp float;
uniform sampler2D wallpaper;
uniform vec2 resolution;
uniform vec2 image_size;
uniform float progress;
out vec4 frag_color;

void main() {
    // PIL image rows run top to bottom; preserve the existing centered crop.
    vec2 uv = vec2(gl_FragCoord.x / resolution.x, 1.0 - gl_FragCoord.y / resolution.y);
    vec2 scale = resolution / min(resolution.x, resolution.y);
    vec2 p = (uv - 0.5) * scale;
    float radius = length(p);
    vec2 radial = p / max(radius, 0.0001);

    // One expanding annulus, with a fixed thickness of 20% of the short side.
    // Move only the wave front: never zoom the image or pull it from the center.
    float half_width = 0.10;
    float reach = length(scale * 0.5);
    float front = (reach + half_width) * progress;
    float distance = (radius - front) / half_width;
    float band = 1.0 - smoothstep(0.55, 1.0, abs(distance));
    float envelope = smoothstep(0.0, 0.035, progress)
                   * (1.0 - smoothstep(0.96, 1.0, progress));
    float center = smoothstep(0.0, 0.025, radius);
    float edge = smoothstep(0.0, 0.025, uv.x) * smoothstep(0.0, 0.025, 1.0 - uv.x)
               * smoothstep(0.0, 0.025, uv.y) * smoothstep(0.0, 0.025, 1.0 - uv.y);
    float mask = band * envelope * center * edge;
    if (mask <= 0.0) {
        frag_color = vec4(0.0);
        return;
    }

    // Local refraction across the ring's cross-section, not radial image scaling.
    // Limit the offset to 1.2% of the short side; pixels outside the ring stay live.
    float wave = sin(distance * 3.14159265);
    vec2 displacement = radial / scale * 0.012 * wave * mask;
    float screen_aspect = resolution.x / resolution.y;
    float image_aspect = image_size.x / image_size.y;
    vec2 crop = vec2(min(1.0, screen_aspect / image_aspect),
                     min(1.0, image_aspect / screen_aspect));
    vec3 color = texture(wallpaper, (uv - displacement - 0.5) * crop + 0.5).rgb;
    frag_color = vec4(color * mask, mask);
}
