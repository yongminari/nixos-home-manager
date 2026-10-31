#version 300 es
precision highp float;
uniform sampler2D wallpaper;
uniform vec2 resolution;
uniform vec2 image_size;
uniform float progress;
uniform vec2 direction;
out vec4 frag_color;

void main() {
    // PIL 이미지의 첫 행은 위쪽입니다. Noctalia의 기본 crop 모드와 맞춥니다.
    vec2 uv = vec2(gl_FragCoord.x / resolution.x, 1.0 - gl_FragCoord.y / resolution.y);
    float screen_aspect = resolution.x / resolution.y;
    float image_aspect = image_size.x / image_size.y;
    vec2 crop = vec2(min(1.0, screen_aspect / image_aspect),
                     min(1.0, image_aspect / screen_aspect));
    // 중앙에서 먼저 출발하고 바깥쪽은 최대 266ms 뒤에 따라옵니다.
    // 위치별 위상차가 있어 화면 전체가 평행 이동하지 않고 실제로 휘어집니다.
    float radius = clamp(length((uv - 0.5) * 2.0) / sqrt(2.0), 0.0, 1.0);
    float delay = 0.28 * radius;
    float phase = clamp((progress - delay) / 0.72, 0.0, 1.0);
    // 한 번 끌려갔다 반대 방향으로 작게 튕기며 감쇠합니다.
    float wave = sin(phase * 2.5 * 3.14159265) * exp(-3.2 * phase);
    wave *= 1.0 - smoothstep(0.72, 1.0, phase);
    // 가로/세로 모두 짧은 화면 변 길이 기준으로 동일한 픽셀 강도를 사용합니다.
    // 이동축 끝의 좁은 영역만 고정하여 이미지 경계가 늘어지는 것을 막습니다.
    float axis = dot(uv, abs(direction));
    float edge = smoothstep(0.0, 0.09, axis) * smoothstep(0.0, 0.09, 1.0 - axis);
    vec2 pixel_scale = vec2(min(resolution.x, resolution.y)) / resolution;
    uv -= direction * pixel_scale * 0.12 * wave * edge;
    vec3 color = texture(wallpaper, (uv - 0.5) * crop + 0.5).rgb;
    // 시작/종료 시 실제 배경으로 페이드하여 레이어 생성 경계를 숨깁니다.
    float alpha = smoothstep(0.0, 0.04, progress) * (1.0 - smoothstep(0.94, 1.0, progress));
    frag_color = vec4(color * alpha, alpha);
}
