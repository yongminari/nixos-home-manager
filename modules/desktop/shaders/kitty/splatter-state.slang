#language slang 2026
import kitty_custom_shader_types;

// Keep normalized cursor edges after Kitty retires its trail geometry.
// Three bands store eight coordinates in RGB. Alpha must stay 1: Kitty
// premultiplies outputs, and its RGBA16 textures only store values in [0, 1].
// Sample band centers to avoid interpolating between adjacent coordinates.
public float4 fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    if (d.cursor_trail_state == 0.0) return t.persist.Sample(t.pos);
    float4 e = d.cursor_trail_edge;
    float4 p = d.cursor_trail_prev_edge;
    if (e.y <= e.x || e.z <= e.w) return float4(0.0, 0.0, 0.0, 1.0);
    if (p.y <= p.x || p.z <= p.w) p = e;
    if (t.pos.x < 1.0 / 3.0) return float4(e.xyz, 1.0);
    if (t.pos.x < 2.0 / 3.0) return float4(e.w, p.xy, 1.0);
    return float4(p.zw, 0.0, 1.0);
}
