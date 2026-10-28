// sRGB -> Linear conversion (needed because Ghostty passes sRGB values but the shader pipeline operates in linear color space)
vec3 sRGBToLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

// --- CONFIGURATION ---
const float DURATION = 0.5; // seconds; keep the cursor trail visible longer
const float TRAIL_DISTANCE_RATIO = 1.0; // initial length relative to cursor travel, independent of window size
const float TRAIL_OPACITY = 0.35;
const float THRESHOLD_MIN_DISTANCE = 0.5; // units of cursor width
const float BLUR = 2.0; // antialiasing in pixels

// Ease-out motion: the trailing edge catches up quickly, then settles gently.
float trailOffset(float x, float initialLength) {
    return initialLength * (1.0 - x) * (1.0 - x);
}

float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
{
    vec2 d = abs(p - xy) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Based on Inigo Quilez's 2D distance functions article: https://iquilezles.org/articles/distfunctions2d/
// Potencially optimized by eliminating conditionals and loops to enhance performance and reduce branching

float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
    vec2 e = b - a;
    vec2 w = p - a;
    vec2 proj = a + e * clamp(dot(w, e) / max(dot(e, e), 1e-12), 0.0, 1.0);
    float segd = dot(p - proj, p - proj);
    d = min(d, segd);

    float c0 = step(0.0, p.y - a.y);
    float c1 = 1.0 - step(0.0, p.y - b.y);
    float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
    float allCond = c0 * c1 * c2;
    float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
    float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
    s *= flip;
    return d;
}

float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
    float s = 1.0;
    float d = dot(p - v0, p - v0);

    d = seg(p, v0, v3, s, d);
    d = seg(p, v1, v0, s, d);
    d = seg(p, v2, v1, s, d);
    d = seg(p, v3, v2, s, d);

    return s * sqrt(d);
}

vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

float antialising(float distance) {
	return 1. - smoothstep(0., normalize(vec2(BLUR, BLUR), 0.).x, distance);
}

float determineIfTopRightIsLeading(vec2 a, vec2 b) {
    float condition1 = step(b.x, a.x) * step(a.y, b.y); // a.x < b.x && a.y > b.y
    float condition2 = step(a.x, b.x) * step(b.y, a.y); // a.x > b.x && a.y < b.y

    // if neither condition is met, return 1 (else case)
    return 1.0 - max(condition1, condition2);
}

vec2 getRectangleCenter(vec4 rectangle) {
    return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.));
}


void mainImage(out vec4 fragColor, in vec2 fragCoord){
    // Native cursor opacity is zero because cursor_glow.glsl draws the fading cursor.
    vec4 TRAIL_COLOR = vec4(sRGBToLinear(iCurrentCursorColor.rgb), 1.0);
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    #endif

    // normalization & setup(-1, 1 coords)
    vec2 vu = normalize(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);
    
    vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));

    vec2 centerCC = currentCursor.xy - (currentCursor.zw * offsetFactor);
    vec2 centerCP = previousCursor.xy - (previousCursor.zw * offsetFactor);

    vec2 delta = centerCP - centerCC;
    float lineLength = length(delta);

     float sdfCurrentCursor = getSdfRectangle(vu, centerCC, currentCursor.zw * 0.5);
	
     vec4 newColor = vec4(fragColor);
	
     float minDist = currentCursor.z * THRESHOLD_MIN_DISTANCE;
     float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
     if (lineLength > minDist && progress < 1.0) {
         // ANIMATION logic
        
        // Keep the front at the real cursor; scale the initial trail to the actual move.
        float head_eased = 1.0;
        float initialLength = lineLength * TRAIL_DISTANCE_RATIO;
        float tail_eased = 1.0 - trailOffset(progress, initialLength) / lineLength;

        // detect straight moves
        vec2 delta_abs = abs(centerCC - centerCP); 
        float threshold = 0.001;
        float isHorizontal = step(delta_abs.y, threshold);
        float isVertical = step(delta_abs.x, threshold);
        float isStraightMove = max(isHorizontal, isVertical);

        // -- Making the parallelogram sdf (diagonal move) --

        // animate the TOP-LEFT corners
        vec2 head_pos_tl = mix(previousCursor.xy, currentCursor.xy, head_eased);
        vec2 tail_pos_tl = mix(previousCursor.xy, currentCursor.xy, tail_eased);

        float isTopRightLeading = determineIfTopRightIsLeading(head_pos_tl, tail_pos_tl);
        float isBottomLeftLeading = 1.0 - isTopRightLeading;
        
        // v0, v1 : "front" of the trail (head)
        vec2 v0 = vec2(head_pos_tl.x + currentCursor.z * isTopRightLeading, head_pos_tl.y - currentCursor.w);
        vec2 v1 = vec2(head_pos_tl.x + currentCursor.z * isBottomLeftLeading, head_pos_tl.y);
        
        // v2, v3: "back" of the trail (tail)
        vec2 v2 = vec2(tail_pos_tl.x + currentCursor.z * isBottomLeftLeading, tail_pos_tl.y);
        vec2 v3 = vec2(tail_pos_tl.x + currentCursor.z * isTopRightLeading, tail_pos_tl.y - previousCursor.w);

        float sdfTrail_diag = getSdfParallelogram(vu, v0, v1, v2, v3);

        // -- Making the rectangle sdf (straight move) --

        vec2 head_center = mix(centerCP, centerCC, head_eased);
        vec2 tail_center = mix(centerCP, centerCC, tail_eased);

        vec2 min_center = min(head_center, tail_center);
        vec2 max_center = max(head_center, tail_center);
        
        vec2 box_size = (max_center - min_center) + currentCursor.zw;
        vec2 box_center = (min_center + max_center) * 0.5;

        float sdfTrail_rect = getSdfRectangle(vu, box_center, box_size * 0.5);

        // -- FINAL SELECTING AND DRAWING --
        float sdfTrail = mix(sdfTrail_diag, sdfTrail_rect, isStraightMove);
        
        // Fade toward the trailing edge and over time, preserving text underneath.
        vec2 trailVector = head_center - tail_center;
        float alongTrail = clamp(dot(vu - tail_center, trailVector)
            / max(dot(trailVector, trailVector), 1e-12), 0.0, 1.0);
        float spatialFade = smoothstep(0.0, 1.0, alongTrail);
        float timeFade = 1.0 - progress;
        float trailAlpha = antialising(sdfTrail) * TRAIL_OPACITY
            * TRAIL_COLOR.a * spatialFade * timeFade;
        newColor.rgb = mix(newColor.rgb, TRAIL_COLOR.rgb, trailAlpha);

        // punch hole
        newColor = mix(newColor, fragColor, step(sdfCurrentCursor, 0.));
    }

    fragColor = newColor;
}
