#language slang 2026
import kitty_custom_shader_types;
// Expand the reserved history pixels into the geometry layout used by splatter.
public float4 fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    float index = t.pos.x < 1.0 / 3.0 ? 2.5 : (t.pos.x < 2.0 / 3.0 ? 3.5 : 4.5);
    return t.persist.Sample(float2(index, 0.5) / float2(d.viewport_size_pixels));
}
