// Shared opening spring: three rebounds, halving each opposite extremum.
float opening_rebound(float time, float first_peak, float overshoot) {
    float rebound_time = clamp((time - first_peak) / (1.0 - first_peak), 0.0, 1.0);
    // Each half-cycle lasts 72% of the previous one: six turns before 1.0.
    float duration_ratio = 0.72;
    float phase = log(1.0 - rebound_time * (1.0 - pow(duration_ratio, 6.0)))
                / log(duration_ratio);
    phase = clamp(phase, 0.0, 6.0);
    float segment = min(floor(phase), 5.0);
    float amplitude = overshoot * pow(0.5, segment)
                    * (mod(segment, 2.0) < 1.0 ? 1.0 : -1.0);
    float next_amplitude = segment < 5.0 ? -0.5 * amplitude : 0.0;
    float blend = 0.5 - 0.5 * cos(3.14159265 * (phase - segment));
    return mix(amplitude, next_amplitude, blend);
}
