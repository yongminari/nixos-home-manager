// CONFIGURATION: linear-light intensity and animation speed.
const float INTENSITY = 0.025;
const float SPEED = 0.18;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = texture(iChannel0, uv);
    vec2 p = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float t = iTime * SPEED;

    // Broad moving curtains cover the entire window, without displacing text.
    float wave = p.y + 0.22 * sin(p.x * 3.0 + t)
        + 0.12 * sin(p.x * 6.0 - t * 0.7);
    float curtain = 0.5 + 0.5 * sin(wave * 9.0 + t);
    curtain = curtain * curtain;
    float hue = 0.5 + 0.5 * sin(p.x * 2.0 + p.y + t * 0.6);
    vec3 aurora = mix(vec3(0.08, 0.65, 0.52), vec3(0.38, 0.16, 0.8), hue);
    float luminance = dot(fragColor.rgb, vec3(0.2126, 0.7152, 0.0722));
    float backgroundMask = 1.0 - smoothstep(0.05, 0.45, luminance);
    fragColor.rgb += aurora * (0.2 + 0.8 * curtain)
        * INTENSITY * backgroundMask * fragColor.a;
}
