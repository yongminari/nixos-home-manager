#language slang 2026
import kitty_custom_shader_types;

// Brief, color-preserving softening of changed foreground after a large update.
// History is captured before this pass, so the effect cannot trigger itself.
public float4 fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    float2 size = float2(d.viewport_size_pixels);
    float response = t.b.Sample(float2(0.5, 0.5) / size).r;
    if (response <= 0.0 || t.pos.y < d.central_area.y + 32.0 / size.y
            || t.pos.y > d.central_area.y + d.central_area.w - 32.0 / size.y) return color;

    float envelope = smoothstep(0.0, 1.0, response);
    float2 radius = float2(2.4 * envelope) / size;
    float4 blurred = float4(0.0);
    float changedInk = 0.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            float2 uv = t.pos + float2(x, y) * radius;
            float4 sampleColor = t.backbuffer.Sample(uv);
            float weight = (x == 0 ? 2.0 : 1.0) * (y == 0 ? 2.0 : 1.0);
            blurred += sampleColor * weight / 16.0;
            float3 difference = abs(sampleColor.rgb / max(sampleColor.a, 0.001)
                                    - d.active_window_background.rgb);
            float ink = smoothstep(0.055, 0.22, max(difference.r, max(difference.g, difference.b)));
            float changed = smoothstep(0.0, 0.15, t.b.Sample(uv).b);
            changedInk = max(changedInk, ink * changed);
        }
    }
    // Keep window opacity fixed; only changed glyphs and their immediate halo soften.
    float3 rgb = lerp(color.rgb, blurred.rgb, 0.85 * envelope * changedInk);
    return float4(rgb, color.a);
}
