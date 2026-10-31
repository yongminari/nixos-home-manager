#language slang 2026
import kitty_custom_shader_types;

static const float RESPONSE_SECONDS = 0.32;
static const float COOLDOWN_SECONDS = 0.65;
static const float CHANGE_RATIO = 0.50;
static const float MIN_CHANGED_SAMPLES = 90.0;

// persist is RGBA16 UNORM. Store all state in RGB with opaque alpha.
// Pixel 0: response, cooldown, marker. Pixel 1: wrapped clock and viewport size.
// Pixels 2..4: cursor geometry; pixel 5: theme. Rest: two color signatures + mask.
public float4 fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    float2 size = float2(d.viewport_size_pixels);
    float2 pixel = floor(t.pos * size);
    float4 old = t.persist.Sample(float2(0.5, 0.5) / size);
    float3 timing = t.persist.Sample(float2(1.5, 0.5) / size).rgb;
    float3 theme = t.persist.Sample(float2(5.5, 0.5) / size).rgb;
    float clock = frac(d.timestamp / 16.0);
    float dt = min(frac(clock - timing.x) * 16.0, 1.0);
    bool valid = abs(old.b - 0.5) < 0.01
              && all(abs(timing.yz * 16384.0 - size) < float2(1.0))
              && all(abs(theme - d.active_window_background.rgb) < float3(0.01))
              && d.timestamp - d.last_rendered_at < 1.0;
    if (pixel.y < 1.0 && pixel.x < 6.0) {
        if (pixel.x < 1.0) {
            float response = valid ? max(0.0, old.r - dt / RESPONSE_SECONDS) : 0.0;
            float cooldown = valid ? max(0.0, old.g - dt / COOLDOWN_SECONDS) : 0.0;
            if (valid && cooldown <= 0.0) {
                float foreground = 0.0, changed = 0.0;
                for (int y = 0; y < 18; ++y) {
                    for (int x = 0; x < 32; ++x) {
                        float2 stats = t.a.Sample((float2(x, y) + 0.5) / size).rg;
                        foreground += stats.x * 16.0;
                        changed += stats.y * 16.0;
                    }
                }
                if (changed >= MIN_CHANGED_SAMPLES && changed >= CHANGE_RATIO * foreground) {
                    response = 1.0;
                    cooldown = 1.0;
                }
            }
            return float4(response, cooldown, 0.5, 1);
        }
        if (pixel.x < 2.0) return float4(clock, size / 16384.0, 1);
        if (pixel.x >= 5.0) return float4(d.active_window_background.rgb, 1);
        float4 e = d.cursor_trail_edge, p = d.cursor_trail_prev_edge;
        if (d.cursor_trail_state == 0.0 || e.y <= e.x || e.z <= e.w)
            return valid ? t.persist.Sample((pixel + 0.5) / size) : float4(0, 0, 0, 1);
        if (p.y <= p.x || p.z <= p.w) p = e;
        if (pixel.x < 3.0) return float4(e.xyz, 1);
        if (pixel.x < 4.0) return float4(e.w, p.xy, 1);
        return float4(p.zw, 0, 1);
    }
    float4 raw = t.backbuffer.Sample(t.pos);
    float3 rgb = raw.rgb / max(raw.a, 0.001);
    float2 signature = float2(dot(rgb, float3(0.299, 0.587, 0.114)), dot(rgb, float3(0.61, 0.13, 0.26)));
    float3 prev = t.persist.Sample(t.pos).rgb;
    float mask = valid ? max(0.0, prev.b - dt / RESPONSE_SECONDS) : 0.0;
    if (valid && max(abs(signature.x - prev.r), abs(signature.y - prev.g)) > 0.075) mask = 1.0;
    return float4(signature, mask, 1);
}
