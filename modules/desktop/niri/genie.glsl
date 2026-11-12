// 원래 화면에 구김과 음영을 만든 뒤, 그 표면을 기존 지니 효과로 흡입합니다.
// 위치마다 다른 크기의 찌그러짐을 만듭니다. 시간 난수는 쓰지 않아
// 같은 종이 조각이 구겨지는 동안 주름이 깜빡이거나 이동하지 않습니다.
float paper_hash(vec2 cell) {
    return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}
// 공간에 고정된 밀도 지도: 촘촘한 구김이 군데군데 모이고 경계는 자연스럽게 이어집니다.
float paper_density(vec2 point) {
    vec2 cell = floor(point);
    vec2 f = fract(point);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(paper_hash(cell), paper_hash(cell + vec2(1.0, 0.0)), f.x),
               mix(paper_hash(cell + vec2(0.0, 1.0)),
                   paper_hash(cell + vec2(1.0, 1.0)), f.x), f.y);
}
// 불규칙하게 흩어진 점 사이의 경계로 연결된 구김을 만듭니다.
// 넓은 면을 남기고 경계 가까이에만 좁은 능선과 골을 집중시킵니다.
float paper_seam(vec2 point) {
    vec2 cell = floor(point);
    vec2 local = fract(point);
    float nearest = 100.0;
    float second = 100.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 offset = vec2(float(x), float(y));
            vec2 seed = cell + offset;
            vec2 jitter = vec2(paper_hash(seed), paper_hash(seed + 47.2));
            vec2 v = offset + 0.15 + 0.70 * jitter - local;
            float d = dot(v, v);
            second = min(second, max(nearest, d));
            nearest = min(nearest, d);
        }
    }
    return max(sqrt(second) - sqrt(nearest), 0.0);
}
float paper_crumple(vec2 point) {
    vec2 warped = point * vec2(7.3, 9.1);
    warped += 0.12 * vec2(sin(point.y * 13.3 + point.x * 4.7),
                         sin(point.x * 10.1 - point.y * 5.3));
    float seam = paper_seam(warped);
    float fine = paper_seam(mat2(1.6, 0.9, -0.8, 1.7) * warped + 8.3);
    // 둥근 돌출선을 쌓지 않고, 골에서 넓은 면으로 이어지는 쐐기 단면을 만듭니다.
    // 서로 다른 크기의 면이 겹치면서 접힌 면의 방향과 깊이가 달라집니다.
    float broad = pow(seam + 0.003, 0.72);
    float small = pow(fine + 0.003, 0.78);
    float broken = 0.5 + 0.5 * smoothstep(-0.25, 0.65,
                                        sin(point.x * 19.0 + point.y * 13.0));
    float plane = 0.10 * sin(point.x * 9.0 + point.y * 6.0)
                + 0.08 * sin(point.y * 13.0 - point.x * 4.0);
    // 기존 크기, 약 1/4 크기, 약 1/7 크기의 구김을 공간별로 섞습니다.
    // 잔주름의 높이는 낮춰 작은 구김이 큰 덩어리처럼 솟지 않게 합니다.
    float density = smoothstep(0.30, 0.70, paper_density(point * vec2(4.1, 5.3) + 12.7));
    float tight = paper_seam(mat2(3.4, 1.7, -1.5, 3.6) * warped + 21.4);
    float micro = paper_seam(mat2(5.8, -3.4, 3.6, 6.1) * warped + 43.8);
    float clusters = smoothstep(0.42, 0.72, paper_density(point * vec2(8.3, 9.7) + 31.2));
    float wrinkles = 0.18 * (pow(tight + 0.003, 0.76) - 0.30)
                   + 0.085 * clusters * (pow(micro + 0.003, 0.78) - 0.30);
    return plane + 0.90 * broad + 0.35 * broken * small - 0.35
           + density * wrinkles;
}
// S자 경로의 왼쪽 굴곡에서 50%, 오른쪽에서 20%, 출구에서 0% 폭을 남깁니다.
float suction_path_width(float y) {
    if (y < 0.30)
        return mix(1.0, 0.50, smoothstep(0.0, 0.30, y));
    if (y < 0.70)
        return mix(0.50, 0.20, smoothstep(0.30, 0.70, y));
    return mix(0.20, 0.0, smoothstep(0.70, 1.0, y));
}
vec4 genie_color(vec3 coords_geo, vec3 size_geo, float progress, float side) {
    float p = clamp(progress, 0.0, 1.0);
    if (p <= 0.0)
        return texture2D(niri_tex, (niri_geo_to_tex * coords_geo).st);
    if (p >= 1.0)
        return vec4(0.0);

    // 앞 35%는 구김이 깊어지는 정도에 맞춰 화면도 중심으로 모읍니다.
    // 구김이 약 74% 진행됐을 때 흡입을 시작해 마지막 구김과 121ms 겹칩니다 (전체 1.1초).
    float crease = smoothstep(0.02, 0.35, p);
    p = clamp((p - 0.24) / 0.76, 0.0, 1.0);
    // 창 최하단 가운데의 바늘구멍으로 가까운 표면부터 흡입합니다.
    // 픽셀 거리로 계산하므로 가로세로 비율이 달라도 구멍은 원형입니다.
    vec2 halfSize = max(size_geo.xy * 0.5, vec2(1.0));
    vec2 sink = vec2(0.5, 1.0);
    // 위쪽에서는 왼쪽, 아래쪽에서는 오른쪽으로 휘었다가 흡입점으로 돌아옵니다.
    // 시간을 따라 창을 흔들지 않고, 높이에 고정된 S자 경로를 따라 흘려보냅니다.
    float pathY = clamp(coords_geo.y, 0.0, 1.0);
    float pathStrength = smoothstep(0.0, 0.40, p);
    float bend = 0.24 * pathStrength;
    float pathWidth = max(mix(1.0, suction_path_width(pathY), pathStrength), 0.0001);
    float pathWidthSlope = pathStrength * (suction_path_width(pathY + 0.001)
                         - suction_path_width(pathY - 0.001)) / 0.002;
    float bendOffset = -bend * sin(6.2831853 * pathY) * sin(3.14159265 * pathY);
    float bendSlope = -bend * (6.2831853 * cos(6.2831853 * pathY) * sin(3.14159265 * pathY)
                     + 3.14159265 * sin(6.2831853 * pathY) * cos(3.14159265 * pathY))
                     * size_geo.x / max(size_geo.y, 1.0);
    // 경로 중심을 기준으로 폭을 압축해 내용과 외곽이 함께 가늘어지게 합니다.
    vec2 pathCoords = vec2(0.5 + (coords_geo.x - 0.5 - bendOffset) / pathWidth,
                           coords_geo.y);
    vec2 radial = (pathCoords - sink) * size_geo.xy;
    if (radial.y > 0.0)
        return vec4(0.0);
    // 구멍에서 좌우 가장자리까지는 반 너비, 윗변까지는 전체 높이입니다.
    vec2 reachSize = vec2(halfSize.x, max(size_geo.y, 1.0));
    float radialDistance = length(radial);
    vec2 direction = radial / max(radialDistance, 0.0001);
    if (radialDistance < 0.0001)
        direction = vec2(1.0, 0.0);
    float boundary = 1.0 / max(abs(direction.x) / reachSize.x,
                               abs(direction.y) / reachSize.y);
    float pull = smoothstep(0.0, 0.85, p);
    float tension = smoothstep(0.20, 0.88, p);
    // 바깥 모서리는 중심으로 이동하기보다 안쪽으로 둥글게 말리며 버팁니다.
    vec2 axis = abs(direction) / reachSize;
    float roundedBoundary = 1.0 / pow(pow(axis.x, 4.0) + pow(axis.y, 4.0), 0.25);
    float rim = mix(boundary, roundedBoundary, tension);
    // 외곽 전체를 같은 배율로 회수하지 않습니다. 흡입 거리가 각 표면까지
    // 도달하는 순서대로 기존 방사형 경로를 따라 구멍 안으로 들어갑니다.
    float outer = max(rim * (1.0 - 0.06 * pull), 0.0001);
    float r = radialDistance / outer;
    if (r > 1.0)
        return vec4(0.0);
    float heldIntake = 0.62 * min(halfSize.x, halfSize.y) * pull;
    float release = pow(smoothstep(0.35, 1.0, p), 1.6);
    float intake = mix(heldIntake, length(reachSize), release);
    if (intake >= boundary)
        return vec4(0.0);
    // 처음에는 가장자리가 버티며 늘어납니다. 이후에는 소모된 거리만 더해
    // 같은 경로의 가까운 무늬부터 없애고, 먼 모서리를 마지막에 회수합니다.
    float spanSquared = max(boundary * boundary - heldIntake * heldIntake, 0.0001);
    float exponent = 2.0 + 3.0 * tension;
    float sourceRadius = sqrt(intake * intake + spanSquared * pow(r, exponent));
    vec2 source = sink + direction * sourceRadius / size_geo.xy;
    float radialStretch = max(spanSquared
        * exponent * pow(max(r, 0.0001), exponent - 1.0)
        / (2.0 * max(sourceRadius, 0.0001) * outer), 0.0001);
    float angularStretch = max(sourceRadius / max(radialDistance, 0.0001), 1.0);
    float width = pathWidth / angularStretch;
    float height = 1.0 / radialStretch;
    // 작은 흡입 구멍과 말린 가장자리의 경사를 기존 제한된 명암에 함께 반영합니다.
    float holeRadius = 2.0 * smoothstep(0.0, 0.12, p);
    float holeCoverage = smoothstep(holeRadius, holeRadius + 1.0, radialDistance);
    if (p <= 0.0)
        holeCoverage = 1.0;
    float rimSlope = -1.2 * tension * exp(-pow((r - 0.84) / 0.12, 2.0));
    vec2 funnelSlope = direction * (0.65 * pull * (1.0 - r) + rimSlope);
    // 일정 비율로 축소하지 않고, 서로 다른 위치의 좁은 접힘 띠에서만
    // 표면 좌표를 압축합니다. 접히지 않은 면은 원래 크기에 가깝게 남습니다.
    // 띠의 위치·폭·깊이는 구김 밀도에 따라 달라져 외곽도 비대칭으로 모입니다.
    float folding = crease * crease;
    for (int i = 0; i < 3; i++) {
        float band = float(i);
        float densityX = paper_density(vec2(source.y * 5.3, band * 3.7 + 12.7));
        float centerX = 0.18 + band * 0.30
                      + 0.09 * (2.0 * paper_crumple(vec2(band * 0.37, source.y)));
        float halfX = mix(0.09, 0.025, densityX);
        float depthX = folding * mix(0.055, 0.14, densityX);
        source.x += depthX * (smoothstep(centerX - halfX, centerX + halfX, source.x) - 0.5);

        float densityY = paper_density(vec2(source.x * 4.1, band * 4.3 + 23.1));
        float centerY = 0.22 + band * 0.28
                      + 0.09 * (2.0 * paper_crumple(vec2(source.x, band * 0.41)));
        float halfY = mix(0.10, 0.03, densityY);
        float depthY = folding * mix(0.04, 0.115, densityY);
        source.y += depthY * (smoothstep(centerY - halfY, centerY + halfY, source.y) - 0.5);
    }
    if (source.x < 0.0 || source.x > 1.0 || source.y < 0.0 || source.y > 1.0)
        return vec4(0.0);

    // 변형된 윤곽을 부드럽게 처리하고 기존 28px 모서리 곡률을 유지합니다.
    vec2 point = (source - 0.5) * size_geo.xy;
    float radius = min(28.0, min(size_geo.x, size_geo.y) * 0.5);
    vec2 q = abs(point) - (size_geo.xy * 0.5 - vec2(radius));
    float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
    // Niri의 GLES 셰이더에는 미분 확장이 없으므로 축소율로 픽셀 폭을 추정합니다.
    float aa = max(1.0 / width, 1.0 / height) * (1.0 + 2.0 * folding);
    float coverage = 1.0 - smoothstep(-aa, aa, distance);
    // 지니로 변형하기 전의 표면 좌표에 주름을 고정합니다.
    // 가느다란 끝에서는 세부 조명을 줄여 흡입 중 반짝임을 억제합니다.
    float detail = smoothstep(3.0, 18.0, width * size_geo.x)
                 * smoothstep(6.0, 36.0, height * size_geo.y);
    float relief = crease * detail;
    float surface = paper_crumple(source);
    // 좁은 범위의 양쪽 높이를 비교해 능선은 날카롭게, 면의 명암은 연속적으로 유지합니다.
    // 넓은 면을 흐리지 않고 능선 주변에만 최소한의 완화를 적용합니다.
    float delta = 0.004;
    float slopeX = 0.026 * (paper_crumple(source + vec2(delta, 0.0))
                          - paper_crumple(source - vec2(delta, 0.0))) / (2.0 * delta);
    float slopeY = 0.026 * (paper_crumple(source + vec2(0.0, delta))
                          - paper_crumple(source - vec2(0.0, delta))) / (2.0 * delta);
    // S자 경로의 기울기에 맞춰 표면 조명의 방향도 함께 굽힙니다.
    vec2 normalSlope = relief * vec2(slopeX, slopeY) + funnelSlope;
    normalSlope.x /= pathWidth;
    normalSlope.y -= (bendSlope + pathWidthSlope * (pathCoords.x - 0.5)
                     * size_geo.x / max(size_geo.y, 1.0)) * normalSlope.x;
    vec3 normal = normalize(vec3(-normalSlope, 1.0));
    vec3 light = normalize(vec3(-0.45, -0.55, 1.0));
    // 원래 색을 기준으로 밝기만 완만하게 조절합니다. 최대 변화는 ±30% 이내입니다.
    float response = (dot(normal, light) - light.z) / light.z;
    float shade = 1.0 + 0.30 * relief * response / sqrt(1.0 + response * response);
    // 표면 내용도 국소적으로 눌리고 비틀립니다. 경계에서는 변위를 0으로 만듭니다.
    vec2 anchor = 4.0 * source * (1.0 - source);
    // 기울기를 변위로 쓰면 접힌 경계에서 텍스처가 끊어집니다.
    // 연속적인 높이값으로 원래 체크무늬·글자를 함께 휘게 만듭니다.
    vec2 dent = vec2(surface, paper_crumple(source + vec2(0.23, 0.37)));
    vec2 samplePoint = source + 0.030 * crease * anchor * dent;
    vec4 color = texture2D(niri_tex, (niri_geo_to_tex * vec3(samplePoint, 1.0)).st);
    color.rgb *= shade;

    // 흰색을 섞는 반사광과 골의 추가 암부는 사용하지 않습니다.
    // RGB에 같은 비율을 적용해 원래 색상과 투명도를 유지합니다.

    return color * coverage * holeCoverage;
}
