#language slang 2026
// Port of ../cursor_tail.glsl. Preserve the Ghostty effect's math and tuning.
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



// --- CONFIGURATION ---
static const float DURATION = 0.5; // seconds; keep the cursor trail visible longer
static const float TRAIL_DISTANCE_RATIO = 1.0; // initial length relative to cursor travel, independent of window size
static const float TRAIL_OPACITY = 0.35;
static const float THRESHOLD_MIN_DISTANCE = 0.5; // units of cursor width
static const float BLUR = 2.0; // antialiasing in pixels

// Ease-out motion: the trailing edge catches up quickly, then settles gently.
float trailOffset(float x, float initialLength) {
    return initialLength * (1.0 - x) * (1.0 - x);
}

float getSdfRectangle(in float2 p, in float2 xy, in float2 b)
{
    float2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Based on Inigo Quilez's 2D distance functions article: https://iquilezles.org/articles/distfunctions2d/
// Potencially optimized by eliminating conditionals and loops to enhance performance and reduce branching

float seg(in float2 p, in float2 a, in float2 b, inout float s, float d) {
    float2 e = b - a;
    float2 w = p - a;
    float2 proj = a + e * clamp(dot(w, e) / max(dot(e, e), 1e-12), 0.0, 1.0);
    float segd = dot(p - proj, p - proj);
    d = min(d, segd);

    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float allCond = c0 * c1 * c2;
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    float flip = lerp(1.0, -1.0, step(0.5, allCond + noneCond));
    s *= flip;
    return d;
}

float getSdfParallelogram(in float2 p, in float2 v0, in float2 v1, in float2 v2, in float2 v3) {
    float s = 1.0;
    float d = dot(p - v0, p - v0);

    d = seg(p, v0, v3, s, d);
    d = seg(p, v1, v0, s, d);
    d = seg(p, v2, v1, s, d);
    d = seg(p, v3, v2, s, d);

    return s * sqrt(d);
}

float2 normalize(float2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float antialising(float distance) {
	return 1. - smoothstep(0., normalize(float2(BLUR, BLUR), 0.).x, distance);
}

float determineIfTopRightIsLeading(float2 a, float2 b) {
    float condition1 = step(b.x, a.x) * step(a.y, b.y); // a.x < b.x && a.y > b.y
    float condition2 = step(a.x, b.x) * step(b.y, a.y); // a.x > b.x && a.y < b.y

    // if neither condition is met, return 1 (else case)
    return 1.0 - max(condition1, condition2);
}

float2 getRectangleCenter(float4 rectangle) {
    return float2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.));
}


void mainImage(out float4 fragColor, in float2 fragCoord){
    // Kitty supplies its cursor color in linear RGB; keep its native cursor visible.
    float4 TRAIL_COLOR = float4(iCurrentCursorColor.rgb, 1.0);
    fragColor = inputColor;

    // normalization & setup(-1, 1 coords)
    float2 vu = normalize(fragCoord, 1.);
    float2 offsetFactor = float2(-.5, 0.5);

    float4 currentCursor = float4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
    float4 previousCursor = float4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));

    float2 centerCC = currentCursor.xy - (currentCursor.zw * offsetFactor);
    float2 centerCP = previousCursor.xy - (previousCursor.zw * offsetFactor);

    float2 delta = centerCP - centerCC;
    float lineLength = length(delta);

     float sdfCurrentCursor = getSdfRectangle(vu, centerCC, currentCursor.zw * 0.5);

     float4 newColor = float4(fragColor);

     float minDist = currentCursor.z * THRESHOLD_MIN_DISTANCE;
     float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
     if (lineLength > minDist && progress < 1.0) {
         // ANIMATION logic

        // Keep the front at the real cursor; scale the initial trail to the actual move.
        float head_eased = 1.0;
        float initialLength = lineLength * TRAIL_DISTANCE_RATIO;
        float tail_eased = 1.0 - trailOffset(progress, initialLength) / lineLength;

        // detect straight moves
        float2 delta_abs = abs(centerCC - centerCP);
        float threshold = 0.001;
        float isHorizontal = step(delta_abs.y, threshold);
        float isVertical = step(delta_abs.x, threshold);
        float isStraightMove = max(isHorizontal, isVertical);

        // -- Making the parallelogram sdf (diagonal move) --

        // animate the TOP-LEFT corners
        float2 head_pos_tl = lerp(previousCursor.xy, currentCursor.xy, head_eased);
        float2 tail_pos_tl = lerp(previousCursor.xy, currentCursor.xy, tail_eased);

        float isTopRightLeading = determineIfTopRightIsLeading(head_pos_tl, tail_pos_tl);
        float isBottomLeftLeading = 1.0 - isTopRightLeading;

        // v0, v1 : "front" of the trail (head)
        float2 v0 = float2(head_pos_tl.x + currentCursor.z * isTopRightLeading, head_pos_tl.y - currentCursor.w);
        float2 v1 = float2(head_pos_tl.x + currentCursor.z * isBottomLeftLeading, head_pos_tl.y);

        // v2, v3: "back" of the trail (tail)
        float2 v2 = float2(tail_pos_tl.x + currentCursor.z * isBottomLeftLeading, tail_pos_tl.y);
        float2 v3 = float2(tail_pos_tl.x + currentCursor.z * isTopRightLeading, tail_pos_tl.y - previousCursor.w);

        float sdfTrail_diag = getSdfParallelogram(vu, v0, v1, v2, v3);

        // -- Making the rectangle sdf (straight move) --

        float2 head_center = lerp(centerCP, centerCC, head_eased);
        float2 tail_center = lerp(centerCP, centerCC, tail_eased);

        float2 min_center = min(head_center, tail_center);
        float2 max_center = max(head_center, tail_center);

        float2 box_size = (max_center - min_center) + currentCursor.zw;
        float2 box_center = (min_center + max_center) * 0.5;

        float sdfTrail_rect = getSdfRectangle(vu, box_center, box_size * 0.5);

        // -- FINAL SELECTING AND DRAWING --
        float sdfTrail = lerp(sdfTrail_diag, sdfTrail_rect, isStraightMove);

        // Fade toward the trailing edge and over time, preserving text underneath.
        float2 trailVector = head_center - tail_center;
        float alongTrail = clamp(dot(vu - tail_center, trailVector)
            / max(dot(trailVector, trailVector), 1e-12), 0.0, 1.0);
        float spatialFade = smoothstep(0.0, 1.0, alongTrail);
        float timeFade = 1.0 - progress;
        float trailAlpha = antialising(sdfTrail) * TRAIL_OPACITY
            * TRAIL_COLOR.a * spatialFade * timeFade;
        newColor.rgb = lerp(newColor.rgb, TRAIL_COLOR.rgb, trailAlpha);

        // punch hole
        newColor = lerp(newColor, fragColor, step(sdfCurrentCursor, 0.));
    }

    fragColor = newColor;
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
