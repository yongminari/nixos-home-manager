#language slang 2026
// Port of ../hexglitch_background.glsl. Preserve the Ghostty effect's math and tuning.
// Kitty colors are already linear RGB. Only the procedural background is displaced.
import kitty_custom_shader_types;

static float2 iResolution;
static float iTime;
static uint iFrame;
static float4 inputColor;

float2 glslMod(float2 x, float2 y) { return x - y * floor(x / y); }

// Adapted from fielding/ghostty-shader-adventures at d3dfd8ec316c8761bf75733bb63fb48c49867caf.
// Source: https://github.com/fielding/ghostty-shader-adventures/blob/d3dfd8ec316c8761bf75733bb63fb48c49867caf/shaders/hexglitch.glsl
// Local variant: background-only distortion, no cursor ring, subdued compositing.
// Hex Glitch — hexagonal interference with CRT glitch effects
// Ported from Shadertoy lfscD7 for Ghostty terminal
//
// Hexagonal tiling with ripple interference creates morphing Moiré patterns
// that rotate and shift. CRT-style glitch displacement adds digital chaos.

// ─── Tuning ─────────────────────────────────────────────────────────────────

static const float PATTERN_OPACITY = 0.012;        // Overall hex pattern visibility (linear-light)
static const float MORPH_SPEED = 0.15;            // Speed of pattern morphing
static const float GLITCH_FREQ = 0.15;            // How often glitch bands appear
static const float VIGNETTE_STRENGTH = 0.3;       // Edge darkening

// ─── Human++ palette ────────────────────────────────────────────────────────

static const float3 COL_PINK   = float3(0.906, 0.204, 0.612);
static const float3 COL_CYAN   = float3(0.102, 0.816, 0.839);
static const float3 COL_PURPLE = float3(0.596, 0.443, 0.996);
static const float3 COL_GOLD   = float3(0.949, 0.651, 0.200);
static const float3 COL_BLUE   = float3(0.271, 0.541, 0.886);

// ─── Math ───────────────────────────────────────────────────────────────────

#define kPi    3.14159265359
#define kTwoPi 6.28318530718

float sqr(float a)       { return a * a; }
float saturate(float a)  { return clamp(a, 0.0, 1.0); }
float3  saturate(float3 a)   { return clamp(a, 0.0, 1.0); }
float sin01(float a)     { return 0.5 * sin(a) + 0.5; }
float cos01(float a)     { return 0.5 * cos(a) + 0.5; }
float toRad(float deg)   { return kTwoPi * deg / 360.0; }
float cwiseMax(float3 v)   { return max(v.x, max(v.y, v.z)); }

float SmoothStep3(float x) { return x * x * (3.0 - 2.0 * x); }

float PaddedSmoothStep(float x, float a, float b) {
    return SmoothStep3(clamp(x * (a + b + 1.0) - a, 0.0, 1.0));
}
float PaddedSmoothStep(float x, float a) { return PaddedSmoothStep(x, a, a); }

float KickDrop(float t, float2 p0, float2 p1, float2 p2, float2 p3) {
    if (t < p1.x)
        return lerp(p0.y, p1.y, max(0.0, exp(-sqr((t - p1.x) * 2.146 / (p1.x - p0.x))) - 0.01) / 0.99);
    else if (t < p2.x)
        return lerp(p1.y, p2.y, (t - p1.x) / (p2.x - p1.x));
    else
        return lerp(p3.y, p2.y, max(0.0, exp(-sqr((t - p2.x) * 2.146 / (p3.x - p2.x))) - 0.01) / 0.99);
}

// ─── Hash (FNV) ─────────────────────────────────────────────────────────────

uint HashCombine(uint a, uint b) {
    return (((a << (31u - (b & 31u))) | (a >> (b & 31u)))) ^
           ((b << (a & 31u)) | (b >> (31u - (a & 31u))));
}

uint HashOf(uint i) {
    uint h = (0x811c9dc5u ^ (i & 0xffu)) * 0x01000193u;
    h = (h ^ ((i >> 8u)  & 0xffu)) * 0x01000193u;
    h = (h ^ ((i >> 16u) & 0xffu)) * 0x01000193u;
    h = (h ^ ((i >> 24u) & 0xffu)) * 0x01000193u;
    return h;
}

uint HashOf(uint a, uint b)                 { return HashCombine(HashOf(a), HashOf(b)); }
uint HashOf(uint a, uint b, uint c)         { return HashCombine(HashCombine(HashOf(a), HashOf(b)), HashOf(c)); }
uint HashOf(uint a, uint b, uint c, uint d) { return HashCombine(HashCombine(HashOf(a), HashOf(b)), HashCombine(HashOf(c), HashOf(d))); }

float HashToFloat(uint i) { return float(i) / float(0xffffffffu); }

// ─── PCG Random ─────────────────────────────────────────────────────────────

static uint4 rngSeed;

uint4 PCGAdvance() {
    rngSeed = rngSeed * 1664525u + 1013904223u;
    rngSeed.x += rngSeed.y * rngSeed.w;
    rngSeed.y += rngSeed.z * rngSeed.x;
    rngSeed.z += rngSeed.x * rngSeed.y;
    rngSeed.w += rngSeed.y * rngSeed.z;
    rngSeed ^= rngSeed >> 16u;
    rngSeed.x += rngSeed.y * rngSeed.w;
    rngSeed.y += rngSeed.z * rngSeed.x;
    rngSeed.z += rngSeed.x * rngSeed.y;
    rngSeed.w += rngSeed.y * rngSeed.z;
    return rngSeed;
}

float4 Rand() { return float4(PCGAdvance()) / float(0xffffffffu); }

void PCGInitialise(uint seed) { rngSeed = uint4(20219u, 7243u, 12547u, 28573u) * seed; }

uint RadicalInverse(uint i) {
    i = ((i & 0xffffu) << 16u) | (i >> 16u);
    i = ((i & 0x00ff00ffu) << 8u)  | ((i & 0xff00ff00u) >> 8u);
    i = ((i & 0x0f0f0f0fu) << 4u)  | ((i & 0xf0f0f0f0u) >> 4u);
    i = ((i & 0x33333333u) << 2u)  | ((i & 0xccccccccu) >> 2u);
    i = ((i & 0x55555555u) << 1u)  | ((i & 0xaaaaaaaau) >> 1u);
    return i;
}

float HaltonBase2(uint i) { return float(RadicalInverse(i)) / float(0xffffffffu); }

// ─── Ordered Dither ─────────────────────────────────────────────────────────

static const float4x4 kOrderedDither = float4x4(
    float4(0., 8., 2., 10.), float4(12., 4., 14., 6.),
    float4(3., 11., 1., 9.), float4(15., 7., 13., 5.)
);

float OrderedDither(int2 p) {
    return (kOrderedDither[p.x & 3][p.y & 3] + 1.0) / 17.0;
}

// ─── Hexagonal Tiling ───────────────────────────────────────────────────────

#define kHexRatio float2(1.5, 0.8660254037844387)
#define kBaryScale 0.5773502691896257

float3 Cartesian2DToBarycentric(float2 p) {
    return mul(float3x3(
        float3(0.0, 1.0 / 0.8660254037844387, 0.0),
        float3(1.0, kBaryScale, 0.0),
        float3(-1.0, kBaryScale, 0.0)
    ), float3(p, 0.0));
}

float2 HexTile(in float2 uv, out float3 bary, out int2 ij) {
    float2 uvClip = glslMod(uv + kHexRatio, 2.0 * kHexRatio) - kHexRatio;
    ij = int2((uv + kHexRatio) / (2.0 * kHexRatio)) * 2;
    if (uv.x + kHexRatio.x <= 0.0) ij.x -= 2;
    if (uv.y + kHexRatio.y <= 0.0) ij.y -= 2;

    bary = Cartesian2DToBarycentric(uvClip);
    if (bary.x > 0.0) {
        if (bary.z > 1.0)      { bary += float3(-1, 1, -2); ij += int2(-1, 1); }
        else if (bary.y > 1.0) { bary += float3(-1, -2, 1); ij += int2(1, 1); }
    } else {
        if (bary.y < -1.0)     { bary += float3(1, 2, -1); ij += int2(-1, -1); }
        else if (bary.z < -1.0){ bary += float3(1, -1, 2); ij += int2(1, -1); }
    }

    return float2(bary.y * kBaryScale - bary.z * kBaryScale, bary.x);
}

// ─── Transforms ─────────────────────────────────────────────────────────────

float2 ScreenToWorld(float2 p, float2 res) {
    return (p - res * 0.5) / res.y;
}

float3x3 ViewMatrix(float rot, float sca) {
    float c = cos(rot) / sca, s = sin(rot) / sca;
    return float3x3(float3(c, s, 0.0), float3(-s, c, 0.0), float3(1.0));
}

// ─── Color ──────────────────────────────────────────────────────────────────

float3 Hue(float phi) {
    float c = 6.0 * phi;
    int i = int(c);
    float3 c0 = float3(((i + 4) / 3) & 1, ((i + 2) / 3) & 1, (i / 3) & 1);
    float3 c1 = float3(((i + 5) / 3) & 1, ((i + 3) / 3) & 1, ((i + 1) / 3) & 1);
    return lerp(c0, c1, c - float(i));
}

float3 HSVToRGB(float3 hsv) { return lerp(float3(0.0), lerp(float3(1.0), Hue(hsv.x), hsv.y), hsv.z); }

float3 RGBToHSV(float3 rgb) {
    float3 hsv;
    hsv.z = max(rgb.x, max(rgb.y, rgb.z));
    float chroma = hsv.z - min(rgb.x, min(rgb.y, rgb.z));
    hsv.y = (hsv.z < 1e-10) ? 0.0 : chroma / hsv.z;
    if (chroma < 1e-10)        hsv.x = 0.0;
    else if (hsv.z == rgb.x)   hsv.x = (1.0 / 6.0) * (rgb.y - rgb.z) / chroma;
    else if (hsv.z == rgb.y)   hsv.x = (1.0 / 6.0) * (2.0 + (rgb.z - rgb.x) / chroma);
    else                       hsv.x = (1.0 / 6.0) * (4.0 + (rgb.x - rgb.y) / chroma);
    hsv.x = frac(hsv.x + 1.0);
    return hsv;
}

float3 Overlay(float3 a, float3 b) {
    return float3(
        (a.x < 0.5) ? (2.0 * a.x * b.x) : (1.0 - 2.0 * (1.0 - a.x) * (1.0 - b.x)),
        (a.y < 0.5) ? (2.0 * a.y * b.y) : (1.0 - 2.0 * (1.0 - a.y) * (1.0 - b.y)),
        (a.z < 0.5) ? (2.0 * a.z * b.z) : (1.0 - 2.0 * (1.0 - a.z) * (1.0 - b.z))
    );
}

float3 paletteColor(float t) {
    t = frac(t);
    if (t < 0.2)      return lerp(COL_CYAN, COL_BLUE, t * 5.0);
    else if (t < 0.4) return lerp(COL_BLUE, COL_PURPLE, (t - 0.2) * 5.0);
    else if (t < 0.6) return lerp(COL_PURPLE, COL_PINK, (t - 0.4) * 5.0);
    else if (t < 0.8) return lerp(COL_PINK, COL_GOLD, (t - 0.6) * 5.0);
    else               return lerp(COL_GOLD, COL_CYAN, (t - 0.8) * 5.0);
}

// ─── Core hex pattern ───────────────────────────────────────────────────────

float3 HexRender(float2 uvScreen, float2 res, bool isDisplaced, out float blend) {
    #define kTurns 7
    #define kNumRipples 5
    #define kRippleDelay (float(kNumRipples) / float(kTurns))
    #define kMaxIter 2

    // Per-pixel random values (replaces texture-based Rand)
    PCGInitialise(HashOf(uint(uvScreen.x), uint(uvScreen.y), uint(iFrame)));
    float4 xi = Rand();
    uint hash = HashOf(98796523u, uint(uvScreen.x), uint(uvScreen.y));
    xi.y = HaltonBase2(hash);
    xi.x = xi.y;

    // Time with per-pixel motion blur offset
    float mblur = isDisplaced ? 100.0 : 10.0;
    float time = (iTime + xi.y * mblur / 60.0) * MORPH_SPEED;

    // Phase and interval control the animation state
    float phase = frac(time);
    int interval = (int(time) & 1) << 1;
    float morph, warpedTime;

    if (phase < 0.85) {
        float y = (interval == 0) ? uvScreen.y : (res.y - uvScreen.y);
        warpedTime = (phase / 0.85) - 0.2 * sqrt(y / res.y) - 0.1;
        phase = frac(warpedTime);
        morph = 1.0 - PaddedSmoothStep(sin01(kTwoPi * phase), 0.0, 0.4);
        blend = float(interval / 2) * 0.5;
        if (interval == 2) warpedTime *= 0.5;
    } else {
        time -= 0.8 * MORPH_SPEED * xi.y * mblur / 60.0;
        warpedTime = time;
        phase = (frac(time) - 0.85) / 0.15;
        morph = 1.0;
        blend = (KickDrop(phase, float2(0.0), float2(0.2, -0.1), float2(0.3, -0.1), float2(0.7, 1.0))
                 + float(interval / 2)) * 0.5;
        interval++;
    }

    float beta = abs(2.0 * max(0.0, blend) - 1.0);
    float expMorph = pow(morph, 0.3);
    float kThickness = lerp(0.5, 0.4, morph);
    float kExponent = lerp(0.05, 0.55, morph);
    float kScale = lerp(2.6, 1.1, expMorph);

    // View transform: rotation keyed to blend, fixed zoom
    float3x3 M = ViewMatrix(blend * kTwoPi, 0.35);
    float2 uvView = ScreenToWorld(uvScreen, res);
    int invert = 0;

    // Chromatic aberration (subtle radial distortion)
    uvView /= 1.0 + 0.05 * length(uvView) * xi.z;
    uvView = mul(M, float3(uvView, 1.0)).xy;

    // Warp space for the pattern
    float2 uvWarp = uvView;
    uvWarp.y *= lerp(1.0, 0.1, sqr(1.0 - morph) * xi.y * saturate(sqr(0.5 * (1.0 + uvView.y))));

    float theta = toRad(30.0) * beta;
    float2x2 r = float2x2(cos(theta), -sin(theta), sin(theta), cos(theta));
    uvWarp = mul(transpose(r), uvWarp);

    // Iterate: each pass tiles, checks sub-hexagons, computes ripples, then zooms in
    for (int iterIdx = 0; iterIdx < kMaxIter; ++iterIdx) {
        float3 bary; int2 ij;
        HexTile(uvWarp, bary, ij);

        if (!isDisplaced && any(ij != int2(0))) break;

        // Sub-hexagon subdivision — creates checkerboard fill within hexes
        int subdiv = 1 + int(exp(-sqr(10.0 * lerp(-1.0, 1.0, phase))) * 100.0);
        float thetaSub = kTwoPi * (floor(cos01(kTwoPi * phase) * 12.0) / 6.0);

        HexTile(
            uvWarp * (0.1 + float(subdiv))
            - kHexRatio.y * float2(sin(thetaSub), cos(thetaSub))
              * floor(0.5 + sin01(kTwoPi * phase) * 2.0) / 2.0,
            bary, ij
        );

        uint hexHash = HashOf(uint(phase * 6.0), uint(subdiv), uint(ij.x), uint(ij.y));
        if (hexHash % 2u == 0u) {
            float alpha = PaddedSmoothStep(sin01(phase * 20.0), 0.2, 0.75);
            float dist = lerp(cwiseMax(abs(bary)), length(uvView) * 2.5, 1.0 - alpha);
            float hashSum = bary[int(hexHash % 3u)] + bary[int((hexHash + 1u) % 3u)];

            if (dist > 1.0 - 0.02 * float(subdiv)) invert ^= 1;
            else if (frac(20.0 / float(subdiv) * hashSum) < 0.5) invert ^= 1;
            if (iterIdx == 0) break;
        }

        // Ripple interference — concentric waves from multiple sources create Moiré
        float sigma = 0.0, sigmaW = 0.0;
        for (int j = 0; j < kTurns; ++j) {
            float thetaR = kTwoPi * float(j) / float(kTurns);
            for (int i = 0; i < kNumRipples; ++i) {
                float l = length(uvWarp - float2(cos(thetaR), sin(thetaR))) * 0.5;
                float w = log2(1.0 / (l + 1e-10));
                sigma += frac(l - pow(
                    frac((float(j) + float(i) / kRippleDelay) / float(kTurns) + warpedTime),
                    kExponent
                )) * w;
                sigmaW += w;
            }
        }
        invert ^= int((sigma / sigmaW) > kThickness);

        // Transform for next iteration: rotate, translate, scale
        theta = kTwoPi * (floor(cos01(kTwoPi * -phase) * 30.0) / 6.0);
        uvWarp = mul(transpose(r), (uvWarp + float2(cos(theta), sin(theta)) * 0.5));
        uvWarp *= kScale;
    }

    // Final color: black/white with palette bleed during transitions
    float3 result = float3(float(invert != 0));
    return lerp(1.0 - result, result * lerp(float3(1.0), paletteColor(xi.x), sqr(beta)), beta);
}

// ─── CRT Glitch ─────────────────────────────────────────────────────────────

bool Interfere(inout float2 xy, float2 res) {
    float frameHash = HashToFloat(HashOf(uint(iFrame / 10)));
    bool isDisplaced = false;

    // Static: occasional scanline jitter (CRT PAL interference)
    float interP = 0.01, disp = res.x * 0.01;
    if (frameHash < 0.1) {
        interP = 0.5;
        disp = 0.02 * res.x;
    }
    PCGInitialise(HashOf(uint(xy.y / 2.0), uint(iFrame / 2)));
    float4 xi = Rand();
    if (xi.x < interP) {
        float mag = lerp(-1.0, 1.0, xi.y);
        xy.x -= disp * sign(mag) * sqr(abs(mag));
    }

    // Vertical band displacement
    if (frameHash > 1.0 - GLITCH_FREQ * 0.47) {
        float dX = HashToFloat(HashOf(8783u, uint(iFrame / 10)));
        float dY = HashToFloat(HashOf(364719u, uint(iFrame / 12)));
        if (xy.y < dX * res.y) {
            xy.y -= lerp(-1.0, 1.0, dY) * res.y * 0.2;
            isDisplaced = true;
        }
    }
    // Horizontal band displacement
    else if (frameHash > 1.0 - GLITCH_FREQ) {
        float dX = HashToFloat(HashOf(147251u, uint(iFrame / 9)));
        float dY = HashToFloat(HashOf(287512u, uint(iFrame / 11)));
        float dZ = HashToFloat(HashOf(8756123u, uint(iFrame / 7)));
        if (xy.y > dX * res.y && xy.y < (dX + 0.1 * dZ) * res.y) {
            xy.x -= lerp(-1.0, 1.0, dY) * res.x * 0.5;
            isDisplaced = true;
        }
    }

    return isDisplaced;
}

// ─── Main ───────────────────────────────────────────────────────────────────

void mainImage(out float4 fragColor, in float2 fragCoord) {
    // Displace only the procedural background; text stays at its original pixels.
    float2 xy = fragCoord;
    bool isDisplaced = Interfere(xy, iResolution.xy);

    xy = clamp(xy, float2(0.0), iResolution.xy - float2(1.0));
    float2 termUV = fragCoord / iResolution.xy;
    float4 terminal = inputColor;

    // Ordered dither for posterization in glitch regions
    int2 xyDith = int2(xy) / max(1, int(HashOf(
        uint(iTime + sin(iTime) * 1.5), uint(xy.x / 128.0), uint(xy.y / 128.0)
    ) & 127u));
    float jpegDmg = OrderedDither(xyDith);

    // Render hex interference pattern
    float blend;
    float3 hex = HexRender(xy, iResolution.xy, isDisplaced, blend);

    // Posterize displaced regions (JPEG damage effect)
    if (isDisplaced) {
        hex *= 5.0;
        hex.x += (frac(hex.x) > jpegDmg) ? 1.0 : 0.0;
        hex.y += (frac(hex.y) > jpegDmg) ? 1.0 : 0.0;
        hex.z += (frac(hex.z) > jpegDmg) ? 1.0 : 0.0;
        hex = floor(hex) / 5.0;
    }

    // Color grading: overlay tint + HSV hue shift + gamma
    hex = lerp(hex, Overlay(hex, float3(0.15, 0.29, 0.39)), blend);
    float3 hsv = RGBToHSV(hex);
    hsv.x += -sin((hsv.x + 0.05) * kTwoPi) * 0.07;
    hex = HSVToRGB(hsv);
    hex = saturate(hex);
    hex = pow(hex, float3(0.8));
    hex = lerp(float3(0.1), float3(0.9), hex);

    // Vignette
    float2 vuv = fragCoord / iResolution.xy;
    vuv.x = (vuv.x - 0.5) * (iResolution.x / iResolution.y) + 0.5;
    float vig = lerp(1.0, max(0.0, 1.0 - pow(length(vuv - 0.5) * 1.414 * 0.6, 3.0)), VIGNETTE_STRENGTH);
    hex *= vig;

    // Composite with terminal
    float termLuma = dot(terminal.rgb, float3(0.299, 0.587, 0.114));
    float vis = PATTERN_OPACITY * (1.0 - smoothstep(0.05, 0.45, termLuma));
    float3 result = lerp(terminal.rgb, hex, vis * terminal.a);

    fragColor = float4(result, terminal.a);
}

public float4 fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    iResolution = float2(d.viewport_size_pixels);
    iTime = d.timestamp;
    iFrame = d.frame_counter;
    inputColor = color;
    float4 result;
    mainImage(result, t.pos * iResolution);
    return float4(result.rgb, color.a);
}
