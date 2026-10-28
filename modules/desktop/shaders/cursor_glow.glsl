// CONFIGURATION: halo radius in cursor heights and linear-light intensity.
const float RADIUS = 0.8;
const float INTENSITY = 0.12;
const float FADE_PERIOD = 1.6; // seconds for a complete fade out / fade in
const float MIN_OPACITY = 0.08;
const float MOVE_HOLD = 0.2; // remain bright briefly after cursor movement
const float CORNER_RADIUS = 0.25; // fraction of the shorter block cursor dimension

vec3 sRGBToLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);
    // Ghostty draws the unfocused cursor itself. Respect application cursor hiding.
    if (iFocus == 0 || iCursorVisible == 0) return;
    if (iCurrentCursor.z <= 0.0 || iCurrentCursor.w <= 0.0) return;

    // Ghostty cursor coordinates describe the top-left corner in bottom-up pixels.
    vec2 center = iCurrentCursor.xy + iCurrentCursor.zw * vec2(0.5, -0.5);
    // Round block cursors; preserve thin bar and underline shapes requested by apps.
    float cornerRadius = (iCurrentCursorStyle == 0 || iCurrentCursorStyle == 1)
        ? min(iCurrentCursor.z, iCurrentCursor.w) * CORNER_RADIUS : 0.0;
    vec2 q = abs(fragCoord - center) - iCurrentCursor.zw * 0.5 + cornerRadius;
    float distanceToCursor = length(max(q, vec2(0.0)))
        + min(max(q.x, q.y), 0.0) - cornerRadius;
    float radius = max(iCurrentCursor.w * RADIUS, 1.0);
    float halo = exp(-3.0 * max(distanceToCursor, 0.0) / radius);
    // Apply the halo outside the same rounded outline as the cursor.
    halo *= smoothstep(0.0, 1.5, distanceToCursor);
    float elapsed = max(iTime - max(iTimeCursorChange, iTimeFocus) - MOVE_HOLD, 0.0);
    float fade = mix(MIN_OPACITY, 1.0,
        0.5 + 0.5 * cos(elapsed * 6.28318530718 / FADE_PERIOD));
    vec3 color = sRGBToLinear(iCurrentCursorColor.rgb);

    // Draw the cursor over the original cell instead of fading its text away.
    // Bar and underline dimensions are supplied directly by Ghostty.
    float cursorMask = 1.0 - smoothstep(-1.0, 0.0, distanceToCursor);
    if (iCurrentCursorStyle == 1) {
        cursorMask *= smoothstep(-2.0, -1.0, distanceToCursor);
    }
    float luminance = dot(fragColor.rgb, vec3(0.2126, 0.7152, 0.0722));
    float textMask = smoothstep(0.08, 0.4, luminance);
    fragColor.rgb = mix(fragColor.rgb, color,
        cursorMask * fade * 0.75 * (1.0 - textMask));
    fragColor.rgb += color * halo * INTENSITY * fade * fragColor.a;
}
