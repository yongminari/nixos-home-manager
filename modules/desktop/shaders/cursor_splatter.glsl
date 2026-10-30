// Adapted from fielding/ghostty-shader-adventures at d3dfd8ec316c8761bf75733bb63fb48c49867caf.
// Source: https://github.com/fielding/ghostty-shader-adventures/blob/d3dfd8ec316c8761bf75733bb63fb48c49867caf/shaders/splatter.glsl
// Local variant: cursor splat and trailing paint only; preserve text and alpha.
// Splatter — Ghostty terminal shader
// Fractal paint splatters + interactive cursor paintbrush
// Based on magic box fractal from Shadertoy sdjGRc

const int MAGIC_BOX_ITERS = 11;
const float MAGIC_BOX_MAGIC = 0.55;

// --- Tuning ---
const float SPLAT_OPACITY = 0.09;      // Base paint visibility
const float SPLAT_FALLOFF = 0.7;       // How far splatters spread
const float SPLAT_CUTOFF = 0.65;       // Hard radius cutoff
const float CENTER_THRESH = 0.0;       // Fractal threshold at center
const float EDGE_THRESH = 60.0;        // Fractal threshold at edge
const float DRIFT_SPEED = 0.03;        // Background animation speed

const float CURSOR_SPLAT_SIZE = 0.18;  // Cursor splatter base size
const float CURSOR_BLOOM = 0.18;        // Extra size when typing
const float CURSOR_IDLE_ALPHA = 0.15;  // Splatter visibility when idle
const float CURSOR_ACTIVE_ALPHA = 0.8; // Splatter visibility when typing
const float ACTIVITY_HOLD = 1.0;       // Hold after the last cursor movement
const float ACTIVITY_FADE = 1.0;       // Then fade out smoothly

// Rotation matrix to avoid box-aligned fractal artifacts
const mat3 M = mat3(
    0.28862355854826727, 0.6997227302779844, 0.6535170557707412,
    0.06997493955670424, 0.6653237235314099, -0.7432683571499161,
    -0.9548821651308448, 0.26025457467376617, 0.14306504491456504
);

// --- Human++ palette ---
vec3 paletteColor(int idx) {
    int i = idx % 5;
    if (i == 0) return vec3(0.906, 0.204, 0.612); // pink
    if (i == 1) return vec3(0.102, 0.816, 0.839); // cyan
    if (i == 2) return vec3(0.596, 0.443, 0.996); // purple
    if (i == 3) return vec3(0.949, 0.651, 0.200); // gold
    return vec3(0.271, 0.541, 0.886);              // blue
}

// Smooth palette interpolation
vec3 paletteLerp(float t) {
    float phase = fract(t) * 5.0;
    int ci = int(floor(phase));
    return mix(paletteColor(ci), paletteColor(ci + 1), fract(phase));
}

// --- Fractal ---
float magicBox(vec3 p) {
    p = 1.0 - abs(1.0 - mod(p, 2.0));
    float lastLength = length(p);
    float tot = 0.0;
    for (int i = 0; i < MAGIC_BOX_ITERS; i++) {
        p = abs(p) / max(lastLength * lastLength, 1e-6) - MAGIC_BOX_MAGIC;
        float newLength = length(p);
        tot += abs(newLength - lastLength);
        lastLength = newLength;
    }
    return tot;
}

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

// --- Cursor helpers ---
vec2 cursorCenter(vec4 rect) {
    return vec2(rect.x + rect.z * 0.5, rect.y - rect.w * 0.5);
}

// --- Single splatter ---
// center is in pixel coordinates
vec4 computeSplat(vec2 centerPx, float size, vec3 color, vec2 fragCoord, vec2 fracUV, float seed) {
    vec2 delta = fragCoord - centerPx;
    float screenDist = length(delta) / iResolution.y;

    float cutoff = SPLAT_CUTOFF * size;
    if (screenDist > cutoff) return vec4(0.0);

    float falloff = SPLAT_FALLOFF * size;

    // Each splat samples a unique slice of the fractal volume
    vec3 p = 0.3 * M * vec3(fracUV + seed * 17.3, seed * 5.0);
    float result = magicBox(p);

    float threshold = mix(CENTER_THRESH, EDGE_THRESH, screenDist / falloff);

    if (result > threshold) {
        float alpha = smoothstep(threshold, threshold + 8.0, result);
        alpha *= (1.0 - smoothstep(cutoff * 0.6, cutoff, screenDist));
        return vec4(color, alpha);
    }
    return vec4(0.0);
}

// Composites a splat into the running paint accumulator
void layerSplat(vec4 splat, inout vec3 paint, inout float paintA) {
    paint = mix(paint, splat.rgb, splat.a * (1.0 - paintA));
    paintA = paintA + splat.a * (1.0 - paintA);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec4 terminal = texture(iChannel0, uv);
    fragColor = terminal;
    if (iFocus == 0 || iCursorVisible == 0 || min(iCurrentCursor.z, iCurrentCursor.w) <= 0.0) return;

    // Fractal UV: uniform aspect scaling + slow circular drift
    vec2 fracUV = fragCoord.xy / iResolution.yy;
    fracUV += vec2(
        sin(iTime * DRIFT_SPEED) * 0.5,
        cos(iTime * DRIFT_SPEED * 0.7) * 0.5
    );

    // --- Typing activity ---
    float timeSinceType = iTime - iTimeCursorChange;
    float activity = 1.0 - smoothstep(ACTIVITY_HOLD, ACTIVITY_HOLD + ACTIVITY_FADE, max(timeSinceType, 0.0));
    if (activity <= 0.0) return;
    float heat = 1.0; // Keep the bloom size stable; fade its opacity instead.

    // --- Cursor positions (pixel space) ---
    vec2 curPos = cursorCenter(iCurrentCursor);
    vec2 prevPos = cursorCenter(iPreviousCursor);

    // Accumulate paint
    vec3 paint = vec3(0.0);
    float paintA = 0.0;

    // =========================================
    // CURSOR SPLATTER (follows cursor)
    // =========================================
    {
        // Color smoothly cycles through palette
        vec3 cursorCol = paletteLerp(iTime * 0.15);
        // Size blooms when typing
        float cursorSize = CURSOR_SPLAT_SIZE + CURSOR_BLOOM * heat;
        // More visible when typing, subtle when idle
        float cursorAlpha = mix(CURSOR_IDLE_ALPHA, CURSOR_ACTIVE_ALPHA, heat);

        vec4 splat = computeSplat(curPos, cursorSize, cursorCol, fragCoord, fracUV, 42.0);
        splat.a *= cursorAlpha;

        layerSplat(splat, paint, paintA);
    }

    // =========================================
    // TRAIL SPLATTER (previous cursor, fading)
    // =========================================
    {
        vec3 trailCol = paletteLerp(iTime * 0.15 + 0.4);
        float trailSize = 0.2 + 0.25 * heat;
        // Fades out over ~2 seconds after cursor moves
        float trailFade = pow(1.0 - smoothstep(0.0, 2.0, timeSinceType), 2.0);
        // Only show trail if cursor actually moved
        float moved = smoothstep(0.0, 5.0, length(curPos - prevPos));

        vec4 splat = computeSplat(prevPos, trailSize, trailCol, fragCoord, fracUV, 77.0);
        splat.a *= trailFade * moved * 0.6;

        layerSplat(splat, paint, paintA);
    }

    // =========================================
    // COMPOSITE
    // =========================================
    float termLuma = dot(terminal.rgb, vec3(0.299, 0.587, 0.114));
    // Paint shows more through dark background, fades under bright text
    float visibility = SPLAT_OPACITY * (1.0 - smoothstep(0.05, 0.45, termLuma));
    // Slightly boost when actively typing
    visibility *= 1.0 + heat * 0.3;

    // One second at full intensity, followed by a one-second eased fade.
    visibility *= activity;
    fragColor = vec4(mix(terminal.rgb, paint, paintA * visibility * terminal.a), terminal.a);
}
