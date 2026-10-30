#language slang 2026
// Port of ../cursor_splatter.glsl. Preserve the Ghostty effect's math and tuning.
// Animate from cached cursor geometry, independently of blink and trail expiry.
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

float3 glslMod(float3 x, float y) { return x - y * floor(x / y); }

// Adapted from fielding/ghostty-shader-adventures at d3dfd8ec316c8761bf75733bb63fb48c49867caf.
// Source: https://github.com/fielding/ghostty-shader-adventures/blob/d3dfd8ec316c8761bf75733bb63fb48c49867caf/shaders/splatter.glsl
// Local variant: cursor splat and trailing paint only; preserve text and alpha.
// Splatter — Ghostty terminal shader
// Fractal paint splatters + interactive cursor paintbrush
// Based on magic box fractal from Shadertoy sdjGRc

static const int MAGIC_BOX_ITERS = 11;
static const float MAGIC_BOX_MAGIC = 0.55;

// --- Tuning ---
static const float SPLAT_OPACITY = 0.09;      // Base paint visibility
static const float SPLAT_FALLOFF = 0.7;       // How far splatters spread
static const float SPLAT_CUTOFF = 0.65;       // Hard radius cutoff
static const float CENTER_THRESH = 0.0;       // Fractal threshold at center
static const float EDGE_THRESH = 60.0;        // Fractal threshold at edge
static const float DRIFT_SPEED = 0.03;        // Background animation speed

static const float CURSOR_SPLAT_SIZE = 0.18;  // Cursor splatter base size
static const float CURSOR_BLOOM = 0.18;        // Extra size when typing
static const float CURSOR_IDLE_ALPHA = 0.15;  // Splatter visibility when idle
static const float CURSOR_ACTIVE_ALPHA = 0.8; // Splatter visibility when typing
// The pipeline timer applies a 1-second hold and 1-second fade.

// Rotation matrix to avoid box-aligned fractal artifacts
static const float3x3 M = float3x3(
    0.28862355854826727, 0.6997227302779844, 0.6535170557707412,
    0.06997493955670424, 0.6653237235314099, -0.7432683571499161,
    -0.9548821651308448, 0.26025457467376617, 0.14306504491456504
);

// --- Human++ palette ---
float3 paletteColor(int idx) {
    int i = idx % 5;
    if (i == 0) return float3(0.906, 0.204, 0.612); // pink
    if (i == 1) return float3(0.102, 0.816, 0.839); // cyan
    if (i == 2) return float3(0.596, 0.443, 0.996); // purple
    if (i == 3) return float3(0.949, 0.651, 0.200); // gold
    return float3(0.271, 0.541, 0.886);              // blue
}

// Smooth palette interpolation
float3 paletteLerp(float t) {
    float phase = frac(t) * 5.0;
    int ci = int(floor(phase));
    return lerp(paletteColor(ci), paletteColor(ci + 1), frac(phase));
}

// --- Fractal ---
float magicBox(float3 p) {
    p = 1.0 - abs(1.0 - glslMod(p, 2.0));
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
    return frac(sin(n) * 43758.5453123);
}

// --- Cursor helpers ---
float2 cursorCenter(float4 rect) {
    return float2(rect.x + rect.z * 0.5, rect.y - rect.w * 0.5);
}

// --- Single splatter ---
// center is in pixel coordinates
float4 computeSplat(float2 centerPx, float size, float3 color, float2 fragCoord, float2 fracUV, float seed) {
    float2 delta = fragCoord - centerPx;
    float screenDist = length(delta) / iResolution.y;

    float cutoff = SPLAT_CUTOFF * size;
    if (screenDist > cutoff) return float4(0.0);

    float falloff = SPLAT_FALLOFF * size;

    // Each splat samples a unique slice of the fractal volume
    float3 p = 0.3 * mul(transpose(M), float3(fracUV + seed * 17.3, seed * 5.0));
    float result = magicBox(p);

    float threshold = lerp(CENTER_THRESH, EDGE_THRESH, screenDist / falloff);

    if (result > threshold) {
        float alpha = smoothstep(threshold, threshold + 8.0, result);
        alpha *= (1.0 - smoothstep(cutoff * 0.6, cutoff, screenDist));
        return float4(color, alpha);
    }
    return float4(0.0);
}

// Composites a splat into the running paint accumulator
void layerSplat(float4 splat, inout float3 paint, inout float paintA) {
    paint = lerp(paint, splat.rgb, splat.a * (1.0 - paintA));
    paintA = paintA + splat.a * (1.0 - paintA);
}

void mainImage(out float4 fragColor, in float2 fragCoord) {
    float2 uv = fragCoord.xy / iResolution.xy;
    float4 terminal = inputColor;
    fragColor = terminal;
    if (iFocus == 0 || iCursorVisible == 0 || min(iCurrentCursor.z, iCurrentCursor.w) <= 0.0) return;

    // Fractal UV: uniform aspect scaling + slow circular drift
    float2 fracUV = fragCoord.xy / iResolution.yy;
    fracUV += float2(
        sin(iTime * DRIFT_SPEED) * 0.5,
        cos(iTime * DRIFT_SPEED * 0.7) * 0.5
    );

    // --- Typing activity ---
    float timeSinceType = iTime - iTimeCursorChange;
    float heat = 1.0; // Keep the bloom size stable; fade its opacity instead.

    // --- Cursor positions (pixel space) ---
    float2 curPos = cursorCenter(iCurrentCursor);
    float2 prevPos = cursorCenter(iPreviousCursor);

    // Accumulate paint
    float3 paint = float3(0.0);
    float paintA = 0.0;

    // =========================================
    // CURSOR SPLATTER (follows cursor)
    // =========================================
    {
        // Color smoothly cycles through palette
        float3 cursorCol = paletteLerp(iTime * 0.15);
        // Size blooms when typing
        float cursorSize = CURSOR_SPLAT_SIZE + CURSOR_BLOOM * heat;
        // More visible when typing, subtle when idle
        float cursorAlpha = lerp(CURSOR_IDLE_ALPHA, CURSOR_ACTIVE_ALPHA, heat);

        float4 splat = computeSplat(curPos, cursorSize, cursorCol, fragCoord, fracUV, 42.0);
        splat.a *= cursorAlpha;

        layerSplat(splat, paint, paintA);
    }

    // =========================================
    // TRAIL SPLATTER (previous cursor, fading)
    // =========================================
    {
        float3 trailCol = paletteLerp(iTime * 0.15 + 0.4);
        float trailSize = 0.2 + 0.25 * heat;
        // Fades out over ~2 seconds after cursor moves
        float trailFade = pow(1.0 - smoothstep(0.0, 2.0, timeSinceType), 2.0);
        // Only show trail if cursor actually moved
        float moved = smoothstep(0.0, 5.0, length(curPos - prevPos));

        float4 splat = computeSplat(prevPos, trailSize, trailCol, fragCoord, fracUV, 77.0);
        splat.a *= trailFade * moved * 0.6;

        layerSplat(splat, paint, paintA);
    }

    // =========================================
    // COMPOSITE
    // =========================================
    float termLuma = dot(terminal.rgb, float3(0.299, 0.587, 0.114));
    // Paint shows more through dark background, fades under bright text
    float visibility = SPLAT_OPACITY * (1.0 - smoothstep(0.05, 0.45, termLuma));
    // Slightly boost when actively typing
    visibility *= 1.0 + heat * 0.3;

    // Keep the procedural flow running; fade only its contribution to the frame.
    visibility *= 1.0 - smoothstep(1.0, 2.0, timeSinceType);
    fragColor = float4(lerp(terminal.rgb, paint, paintA * visibility * terminal.a), terminal.a);
}

public float4 fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    iResolution = float2(d.viewport_size_pixels);
    iTime = d.timestamp;
    inputColor = color;
    // Only positions are retained. Time, drift, palette and fractal detail
    // continue to advance on every frame, including throughout the fade.
    float3 first = t.a.Sample(float2(1.0 / 6.0, 0.5)).rgb;
    float3 second = t.a.Sample(float2(0.5, 0.5)).rgb;
    float3 third = t.a.Sample(float2(5.0 / 6.0, 0.5)).rgb;
    float4 e = float4(first, second.x);
    float4 p = float4(second.yz, third.xy);
    if (e.y <= e.x || e.z <= e.w) return color;
    iCurrentCursor = float4(e.x, e.z, e.y - e.x, e.z - e.w) * iResolution.xyxy;
    iPreviousCursor = float4(p.x, p.z, p.y - p.x, p.z - p.w) * iResolution.xyxy;
    iCurrentCursorColor = d.cursor_color;
    // This timer survives trail expiry and restarts on every cursor movement.
    iTimeCursorChange = iTime - 2.0 * t.animation_progress;
    iTimeFocus = iTimeCursorChange;
    iFocus = 1;
    iCursorVisible = 1;
    float4 result;
    mainImage(result, t.pos * iResolution);
    return result;
}
