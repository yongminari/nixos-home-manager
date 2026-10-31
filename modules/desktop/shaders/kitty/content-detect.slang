#language slang 2026
import kitty_custom_shader_types;

// Only the small 32x18 corner contains statistics. Each tile samples 16 points.
// These are raw terminal pixels, before the background/cursor shader groups.
public float4 fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    float2 pixel = floor(t.pos * float2(d.viewport_size_pixels));
    if (pixel.x >= 32.0 || pixel.y >= 18.0) return float4(0, 0, 0, 1);
    float2 resolution = float2(d.viewport_size_pixels);
    float2 origin = d.central_area.xy + float2(0, 32.0 / resolution.y);
    float2 extent = max(d.central_area.zw - float2(0, 64.0 / resolution.y), float2(0.001));
    float foreground = 0.0, changed = 0.0;
    for (int y = 0; y < 4; ++y) {
        for (int x = 0; x < 4; ++x) {
            float2 uv = origin + extent * (pixel + (float2(x, y) + 0.5) / 4.0) / float2(32, 18);
            float4 current = t.backbuffer.Sample(uv);
            float3 rgb = current.rgb / max(current.a, 0.001);
            float luma = dot(rgb, float3(0.299, 0.587, 0.114));
            float chroma = dot(rgb, float3(0.61, 0.13, 0.26));
            float4 previous = t.persist.Sample(uv);
            float bgL = dot(d.active_window_background.rgb, float3(0.299, 0.587, 0.114));
            float bgC = dot(d.active_window_background.rgb, float3(0.61, 0.13, 0.26));
            bool visible = max(abs(luma - bgL), abs(chroma - bgC)) > 0.055
                        || max(abs(previous.r - bgL), abs(previous.g - bgC)) > 0.055;
            bool different = max(abs(previous.r - luma), abs(previous.g - chroma)) > 0.075;
            foreground += visible ? 1.0 : 0.0;
            changed += visible && different ? 1.0 : 0.0;
        }
    }
    return float4(foreground / 16.0, changed / 16.0, 0, 1);
}
