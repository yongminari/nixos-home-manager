// 중앙이 먼저 휘고 양옆이 따라오며 창 오른쪽 아래로 빠져나가는 지니 효과.
// opening은 동일 변형의 역재생입니다.
vec4 genie_color(vec3 coords_geo, vec3 size_geo, float progress, float side) {
    float p = clamp(progress, 0.0, 1.0);
    if (p <= 0.0)
        return texture2D(niri_tex, (niri_geo_to_tex * coords_geo).st);
    if (p >= 1.0)
        return vec4(0.0);

    // 아래쪽이 먼저 오른쪽으로 꺾이고 몸체가 곡선을 따라 수렴합니다.
    float neck = smoothstep(0.0, 0.65, p);
    float pull = smoothstep(0.12, 1.0, p);
    float top = pull * pull;
    float height = max(1.0 - top, 0.0001);
    float row = (coords_geo.y - top) / height;
    if (row < 0.0 || row > 1.0)
        return vec4(0.0);

    float funnel = 0.025 + 0.975 * pow(1.0 - row, 1.6);
    float width = max(mix(1.0, funnel, neck) * (1.0 - 0.97 * pull), 0.0001);
    float sweep = pull + (1.0 - pull) * neck * smoothstep(0.0, 1.0, row);
    float center = 0.5 + side * 0.44 * sweep;
    center += side * 0.09 * sin(row * 3.14159265) * sin(p * 3.14159265);
    center = clamp(center, width * 0.5, 1.0 - width * 0.5);
    vec2 source = vec2((coords_geo.x - center) / width + 0.5, row);
    if (source.x < 0.0 || source.x > 1.0)
        return vec4(0.0);

    // 윗변의 중앙을 먼저 아래로 잡아당깁니다. 양 끝은 뒤늦게 따라와
    // 수평으로 줄어드는 사다리꼴 대신 천이 빨려 들어가는 윤곽을 만듭니다.
    float middle = pow(max(0.0, 1.0 - pow(2.0 * source.x - 1.0, 2.0)), 1.5);
    float sag = 0.62 * sin(p * 3.14159265) * middle;
    source.y = (row - sag) / (1.0 - sag);
    if (source.y < 0.0 || source.y > 1.0)
        return vec4(0.0);

    // 변형된 윤곽을 부드럽게 처리하고 기존 28px 모서리 곡률을 유지합니다.
    vec2 point = (source - 0.5) * size_geo.xy;
    float radius = min(28.0, min(size_geo.x, size_geo.y) * 0.5);
    vec2 q = abs(point) - (size_geo.xy * 0.5 - vec2(radius));
    float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
    // Niri의 GLES 셰이더에는 미분 확장이 없으므로 축소율로 픽셀 폭을 추정합니다.
    float aa = max(1.0 / width, 1.0 / (height * (1.0 - sag)));
    float coverage = 1.0 - smoothstep(-aa, aa, distance);
    vec4 color = texture2D(niri_tex, (niri_geo_to_tex * vec3(source, 1.0)).st);
    return color * coverage * (1.0 - smoothstep(0.96, 1.0, p));
}
