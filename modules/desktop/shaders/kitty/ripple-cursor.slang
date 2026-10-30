#language slang 2026
// Port of ../ripple_cursor.glsl. Preserve the Ghostty effect's math and tuning.
// Kitty colors are already linear RGB. Cursor effects run only while trail data is valid.
import kitty_custom_shader_types;

static float2 iResolution;
static float iTime;
static float4 inputColor;
static float4 iCurrentCursor;
static float4 iPreviousCursor;
static float4 iCurrentCursorColor;
static float iTimeCursorChange;
static float iTimeFocus;
static int iFocus;
static int iCursorVisible;


// CONFIGURATION
static const float DURATION = 0.25;               // How long the ripple animates (seconds)
static const float MAX_RADIUS = 0.05;             // Max radius in normalized coords (0.5 = 1/4 screen height)
static const float RING_THICKNESS = 0.02;             // Ring width in normalized coords
static const float CURSOR_SIZE_CHANGE_THRESHOLD = 0.5; // Triggers rectangle ripple if either dimension changes by this fraction
static const float CURSOR_MOVE_THRESHOLD = 1.0;   // Trigger a ripple on each single-cell move
static const float SOURCE_RIPPLE_THRESHOLD = 3.0; // Also contract a ripple at the source for longer moves
static const float MOVEMENT_EPSILON = 0.001;     // Cell units: tolerate UV-to-pixel rounding at exact cell boundaries
static const float4 COLOR = float4(0.35, 0.36, 0.44, 1.0); // change to iCurrentCursorColor for your cursor's color
static const float BLUR = 3.0;                    // Blur level in pixels
static const float ANIMATION_START_OFFSET = 0.0;        // Start the ripple slightly progressed (0.0 - 1.0)


// Easing functions
float easeOutQuad(float t) {
    return 1.0 - (1.0 - t) * (1.0 - t);
}
float easeInOutQuad(float t) {
    return t < 0.5 ? 2.0 * t * t : 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0;
}
float easeOutCubic(float t) {
    return 1.0 - pow(1.0 - t, 3.0);
}
float easeOutQuart(float t) {
    return 1.0 - pow(1.0 - t, 4.0);
}
float easeOutQuint(float t) {
    return 1.0 - pow(1.0 - t, 5.0);
}
float easeOutExpo(float t) {
    return t == 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * t);
}
float easeOutCirc(float t) {
    return sqrt(1.0 - pow(t - 1.0, 2.0));
}
float easeOutSine(float t) {
    return sin((t * 3.1415916) / 2.0);
}
float easeOutElastic(float t) {
    const float c4 = (2.0 * 3.1415916) / 3.0;
    return t == 0.0 ? 0.0 : t == 1.0 ? 1.0 : pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * c4) + 1.0;
}
float easeOutBounce(float t) {
    const float n1 = 7.5625;
    const float d1 = 2.75;
    if (t < 1.0 / d1) {
        return n1 * t * t;
    } else if (t < 2.0 / d1) {
        return n1 * (t -= 1.5 / d1) * t + 0.75;
    } else if (t < 2.5 / d1) {
        return n1 * (t -= 2.25 / d1) * t + 0.9375;
    } else {
        return n1 * (t -= 2.625 / d1) * t + 0.984375;
    }
}
float easeOutBack(float t) {
    const float c1 = 1.70158;
    const float c3 = c1 + 1.0;
    return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0);
}

// Pulse fade functions
float easeOutPulse(float t) {
    return t * (2.0 - t);
}
float exponentialDecayPulse(float t) {
    return exp(-3.0 * t) * sin(t * 3.1415916);
}

float2 normalize(float2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

void mainImage(out float4 fragColor, in float2 fragCoord){
    fragColor = inputColor;

    // Normalization & setup (-1 to 1 coords)
    float2 vu = normalize(fragCoord, 1.);
    float2 offsetFactor = float2(-.5, 0.5);

    float4 currentCursor = float4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
    float4 previousCursor = float4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));

    float2 centerCC = currentCursor.xy - (currentCursor.zw * offsetFactor);
    float2 centerCP = previousCursor.xy - (previousCursor.zw * offsetFactor);

    // Detect block/bar/underline changes in either dimension.
    float2 cursorSize = max(max(iCurrentCursor.zw, iPreviousCursor.zw), float2(1.0));
    float2 sizeChange = abs(iCurrentCursor.zw - iPreviousCursor.zw) / cursorSize;
    float isModeChange = step(CURSOR_SIZE_CHANGE_THRESHOLD, max(sizeChange.x, sizeChange.y));

    // Use cursor origins so a shape change alone does not count as movement.
    // Cursor dimensions approximate cell size (exact for single-cell block cursors).
    float2 cellSize = cursorSize;
    float2 movementInCells = (iCurrentCursor.xy - iPreviousCursor.xy) / cellSize;
    float movementDistance = length(movementInCells);
    // Kitty's normalized edges can reconstruct a one-cell move as slightly less than 1.0.
    float isMove = step(CURSOR_MOVE_THRESHOLD - MOVEMENT_EPSILON, movementDistance);
    float isLargeMove = step(SOURCE_RIPPLE_THRESHOLD - MOVEMENT_EPSILON, movementDistance);


    // ANIMATION
    float rippleProgress = (iTime - iTimeCursorChange) / DURATION + ANIMATION_START_OFFSET;
    // don't clamp yet; we need to know if it's > 1.0 (finished)
     float isAnimating = 1.0 - step(1.0, rippleProgress); // progress < 1.0 ? 1.0: 0.0

     if (max(isModeChange, isMove) > 0.0 && isAnimating > 0.0) {
        // Apply easing to progress
        // float easedProgress = rippleProgress;
        // float easedProgress = easeOutQuad(rippleProgress);
        // float easedProgress = easeInOutQuad(rippleProgress);
        // float easedProgress = easeOutCubic(rippleProgress);
        // float easedProgress = easeOutQuart(rippleProgress);
        // float easedProgress = easeOutQuint(rippleProgress);
        // float easedProgress = easeOutExpo(rippleProgress);
        float easedProgress = easeOutCirc(rippleProgress);
        // float easedProgress = easeOutSine(rippleProgress);
        // float easedProgress = easeOutBack(rippleProgress);

        // RIPPLE CALCULATION
        float rippleRadius = easedProgress * MAX_RADIUS;

        // float fade = 1.0; // no fade
        // float fade = 1.0 - easedProgress; // linear fade
        float fade = 1.0 - easeOutPulse(rippleProgress);
        // float fade = 1.0 - exponentialDecayPulse(rippleProgress);

        // Calculate distance from frag to cursor center
        float dist = distance(vu, centerCC);

        float sdfRing = abs(dist - rippleRadius) - RING_THICKNESS * 0.5;

        // Size changes use only a rectangular ring, even when the cursor also moves.
        if (isModeChange > 0.0) {
            float2 blockSize = normalize(cursorSize, 0.0);
            float2 aspect = blockSize / max(blockSize.x, blockSize.y);
            float2 halfSize = blockSize * 0.5 + aspect * rippleRadius;
            float2 q = abs(vu - centerCC) - halfSize;
            float sdfRectangle = length(max(q, float2(0.0))) + min(max(q.x, q.y), 0.0);
            sdfRing = abs(sdfRectangle) - RING_THICKNESS * 0.5;
        }

        // Antialias (1-pixel width in normalized coords)
        float antiAliasSize = normalize(float2(BLUR, BLUR), 0.0).x;
        float ripple = (1.0 - smoothstep(-antiAliasSize, antiAliasSize, sdfRing)) * fade;

        // Longer moves pair an expanding destination ring with a contracting source ring.
        if (isLargeMove > 0.0 && isModeChange == 0.0) {
            float sourceRadius = (1.0 - easedProgress) * MAX_RADIUS;
            float sourceDist = distance(vu, centerCP);
            float sourceSdfRing = abs(sourceDist - sourceRadius) - RING_THICKNESS * 0.5;
            float sourceRipple = (1.0 - smoothstep(-antiAliasSize, antiAliasSize, sourceSdfRing)) * fade;
            ripple = max(ripple, sourceRipple);
        }

        // Apply ripple effect
        fragColor = lerp(fragColor, COLOR, ripple * COLOR.a);
    }
    // else: do nothing, keep original fragColor
}

public float4 fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    iResolution = float2(d.viewport_size_pixels);
    iTime = d.timestamp;
    inputColor = color;
    // No stale geometry: Kitty clears these fields after its cursor trail stops.
    if (d.cursor_trail_state == 0.0 || d.cursor_color.a <= 0.0) return color;
    float4 e = d.cursor_trail_edge;
    float4 p = d.cursor_trail_prev_edge;
    if (e.y <= e.x || e.z <= e.w || p.y <= p.x || p.z <= p.w) return color;
    iCurrentCursor = float4(e.x, e.z, e.y - e.x, e.z - e.w) * iResolution.xyxy;
    iPreviousCursor = float4(p.x, p.z, p.y - p.x, p.z - p.w) * iResolution.xyxy;
    iCurrentCursorColor = d.cursor_color;
    iTimeCursorChange = d.cursor_trail_change_time;
    iTimeFocus = iTimeCursorChange;
    iFocus = 1;
    iCursorVisible = 1;
    float4 result;
    mainImage(result, t.pos * iResolution);
    return float4(result.rgb, color.a);
}
