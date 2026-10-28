// CONFIGURATION: halo radius in cursor heights and linear-light intensity.
const float RADIUS = 0.8;
const float INTENSITY = 0.12;

vec3 sRGBToLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
    if (iCurrentCursor.z <= 0.0 || iCurrentCursor.w <= 0.0) return;

    // Ghostty cursor coordinates describe the top-left corner in bottom-up pixels.
    vec2 center = iCurrentCursor.xy + iCurrentCursor.zw * vec2(0.5, -0.5);
    vec2 q = abs(fragCoord - center) - iCurrentCursor.zw * 0.5;
    float distanceToCursor = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
    float radius = max(iCurrentCursor.w * RADIUS, 1.0);
    float halo = exp(-3.0 * max(distanceToCursor, 0.0) / radius);
    // Keep the cursor glyph intact; apply light only outside its rectangle.
    halo *= smoothstep(0.0, 1.5, distanceToCursor);
    float breathe = 0.9 + 0.1 * sin(iTime * 2.0);
    fragColor.rgb += sRGBToLinear(iCurrentCursorColor.rgb)
        * halo * INTENSITY * breathe * iCurrentCursorColor.a * fragColor.a;
}
