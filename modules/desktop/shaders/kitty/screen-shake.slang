#language slang 2026
import kitty_custom_shader_types;

// Match ../screen_shake.glsl; run in a separate, final group to sample all effects.
static const float SHAKE_DURATION = 0.18;
static const float SHAKE_PIXELS = 2.0;

public float4 fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    if (d.cursor_trail_state == 0.0 || d.cursor_color.a <= 0.0) return color;
    float4 e = d.cursor_trail_edge;
    float4 p = d.cursor_trail_prev_edge;
    if (e.y <= e.x || e.z <= e.w || p.y <= p.x || p.z <= p.w) return color;
    float2 resolution = float2(d.viewport_size_pixels);
    float2 movement = (e.xz - p.xz) * resolution;
    float age = d.timestamp - d.cursor_trail_change_time;
    if (length(movement) <= 0.5 || age < 0.0 || age >= SHAKE_DURATION) return color;
    float progress = age / SHAKE_DURATION;
    float envelope = (1.0 - progress) * (1.0 - progress);
    float2 offset = SHAKE_PIXELS * envelope
        * float2(sin(age * 110.0), 0.6 * sin(age * 145.0));
    return t.backbuffer.Sample(t.pos + offset / resolution);
}
