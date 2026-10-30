// Apply last so text, background and cursor effects move together.
// Cursor movement is a typing proxy; navigation and output can also trigger it.
const float SHAKE_DURATION = 0.18;
const float SHAKE_PIXELS = 2.0;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    float age = iTime - iTimeCursorChange;
    vec2 movement = iCurrentCursor.xy - iPreviousCursor.xy;
    bool validCursor = all(greaterThan(iCurrentCursor.zw, vec2(0.0)))
        && all(greaterThan(iPreviousCursor.zw, vec2(0.0)));
    if (iFocus > 0 && validCursor && length(movement) > 0.5
        && age >= 0.0 && age < SHAKE_DURATION) {
        float progress = age / SHAKE_DURATION;
        float envelope = (1.0 - progress) * (1.0 - progress);
        vec2 offset = SHAKE_PIXELS * envelope
            * vec2(sin(age * 110.0), 0.6 * sin(age * 145.0));
        uv += offset / iResolution.xy;
    }
    vec2 halfPixel = 0.5 / iResolution.xy;
    fragColor = texture(iChannel0, clamp(uv, halfPixel, 1.0 - halfPixel));
}
