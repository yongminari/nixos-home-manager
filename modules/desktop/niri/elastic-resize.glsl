// 확대할 때는 변의 중앙이 먼저 늘어나고, 축소할 때는 중앙이 먼저 눌립니다.
// 현재 사각형 안에서 윤곽을 변형하여 Niri의 clip-to-geometry와 함께 사용합니다.
// 중앙을 먼저 당기거나 누른 뒤, 가장자리가 뒤늦게 가속하며 따라옵니다.
vec4 resize_blur_sample(sampler2D tex, mat3 geo_to_tex, vec3 geo, vec2 offset) {
    vec2 sample_geo = clamp(geo.xy + offset, vec2(0.0), vec2(1.0));
    return texture2D(tex, (geo_to_tex * vec3(sample_geo, 1.0)).st);
}

vec4 resize_blur(sampler2D tex, mat3 geo_to_tex, vec3 geo, vec2 radius_geo, float amount) {
    vec4 sharp = texture2D(tex, (geo_to_tex * geo).st);
    if (amount <= 0.0001)
        return sharp;

    // 원형으로 분산한 32개 표본과 가우시안 가중치로 강하게 흐립니다.
    // 격자 간격만 넓혀 글자가 여러 벌로 보이는 현상을 피합니다.
    vec4 color = vec4(0.0);
    // 황금각 분포와 정규화한 가우시안 가중치를 미리 계산합니다.
    // 매 픽셀마다 삼각함수·지수함수를 반복 계산하지 않도록 합니다.
    color += 0.07006986 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(0.12500000, 0.00000000) * radius_geo);
    color += 0.06582454 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(-0.15964505, 0.14624794) * radius_geo);
    color += 0.06183644 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(0.02443623, -0.27843827) * radius_geo);
    color += 0.05808996 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(0.20122224, 0.26245878) * radius_geo);
    color += 0.05457046 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(-0.36926756, -0.06531823) * radius_geo);
    color += 0.05126421 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(0.34980247, -0.22251570) * radius_geo);
    color += 0.04815826 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(-0.11700208, 0.43524190) * radius_geo);
    color += 0.04524050 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(-0.22313565, -0.42963412) * radius_geo);
    color += 0.04249952 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(0.48411511, 0.17679806) * radius_geo);
    color += 0.03992460 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(-0.50364111, 0.20789573) * radius_geo);
    color += 0.03750569 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(0.24278830, -0.51882448) * radius_geo);
    color += 0.03523334 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(0.17941437, 0.57200130) * radius_geo);
    color += 0.03309866 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(-0.54075701, -0.31337974) * radius_geo);
    color += 0.03109331 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(0.63436952, -0.13946436) * radius_geo);
    color += 0.02920946 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(-0.38714585, 0.55067512) * radius_geo);
    color += 0.02743975 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(-0.08943965, -0.69019964) * radius_geo);
    color += 0.02577726 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(0.54907176, 0.46275826) * radius_geo);
    color += 0.02421550 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(-0.73887847, 0.03055494) * radius_geo);
    color += 0.02274835 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(0.53895513, -0.53633233) * radius_geo);
    color += 0.02137010 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(-0.03605819, 0.77979152) * radius_geo);
    color += 0.02007535 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(-0.51281753, -0.61452680) * radius_geo);
    color += 0.01885905 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(0.81235959, 0.10930184) * radius_geo);
    color += 0.01771644 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(-0.68831064, 0.47890861) * radius_geo);
    color += 0.01664305 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(0.18808606, -0.83606138) * radius_geo);
    color += 0.01563470 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(0.43503326, 0.75919106) * radius_geo);
    color += 0.01468744 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(-0.85044841, -0.27131624) * radius_geo);
    color += 0.01379757 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(0.82610240, -0.38168026) * radius_geo);
    color += 0.01296162 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(-0.35788821, 0.85515556) * radius_geo);
    color += 0.01217632 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(-0.31940733, -0.88803376) * radius_geo);
    color += 0.01143859 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(0.84990863, 0.44668817) * radius_geo);
    color += 0.01074556 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(-0.94403465, 0.24884450) * radius_geo);
    color += 0.01009452 * resize_blur_sample(tex, geo_to_tex, geo,
        vec2(0.53659582, -0.83452977) * radius_geo);
    // 블러 반경을 줄이는 대신 선명한 원본으로 크로스페이드합니다.
    return mix(sharp, color, amount);
}

vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {
    float p = niri_clamped_progress;
    // 축소의 중앙 선행량은 목표에서 값·1차·2차 미분이 모두 0이 됩니다.
    // 부분 변형에서 전체 스프링으로 위치·속도·가속도를 이어갑니다.
    if (p >= 1.0)
        return texture2D(niri_tex_next, (niri_geo_to_tex_next * coords_curr_geo).st);

    vec2 size = size_curr_geo.xy;
    vec2 prev_size = size / vec2(niri_curr_geo_to_prev_geo[0][0],
                                 niri_curr_geo_to_prev_geo[1][1]);
    vec2 next_size = size / vec2(niri_curr_geo_to_next_geo[0][0],
                                 niri_curr_geo_to_next_geo[1][1]);
    vec2 delta = next_size - prev_size;

    vec2 growing = step(vec2(0.0), delta);

    // 확대: 중앙이 전체 변화의 35%까지 먼저 늘어나는 동안 모서리는 기다립니다.
    // 이후 모서리의 진행 속도가 중앙보다 빨라지며 95% 지점에서 따라잡습니다.
    float following = p * smoothstep(0.35, 0.95, p);
    // 축소: 중앙이 앞서되 목표에 먼저 멈추지 않고 끝부분과 함께 도착합니다.
    // p + 3*p*(1-p)^3은 단조 증가하며 목표에서 기본 스프링의 속도로 합류합니다.
    float remaining = 1.0 - p;
    float center_lead = 3.0 * p * remaining * remaining * remaining;
    float pressing = p + center_lead;
    vec2 local_progress = mix(vec2(pressing), vec2(following), growing);
    vec2 local_size = prev_size + delta * local_progress;
    // 크기 차이에서 윤곽을 계산하여 중앙이 목표보다 더 눌렸다가 펴지지 않게 합니다.
    vec2 bend = max(1.0 - local_size / size, vec2(0.0));
    // 축소는 실제 렌더 크기에서 선행량만 빼서 픽셀 반올림에 의한 끝점 오차를 피합니다.
    bend = mix(max(-delta * center_lead / size, vec2(0.0)), bend, growing);
    // 단일 축의 중앙 선행 변형은 유지하고, 양 축이 함께 휘는 경우에만
    // 역변환 안정성을 위한 제한을 강화합니다.
    float coupled = smoothstep(0.0, 0.2, min(bend.x, bend.y));
    bend = min(bend, vec2(mix(0.9, 0.45, coupled)));
    vec2 point = coords_curr_geo.xy - 0.5;
    vec2 source = coords_curr_geo.xy;
    vec2 extent = vec2(1.0);

    // 너비는 좌우 중앙, 높이는 상하 중앙이 먼저 움직입니다.
    // 양쪽 축이 함께 바뀔 때도 윤곽을 맞추도록 역변환을 반복합니다.
    for (int i = 0; i < 4; i++) {
        vec2 across = clamp(2.0 * source.yx - 1.0, -1.0, 1.0);
        vec2 middle = pow(max(vec2(0.0), 1.0 - across * across), vec2(2.0));
        vec2 lag = mix(middle, 1.0 - middle, growing);
        extent = 1.0 - bend * lag;
        source = point / extent + 0.5;
    }

    vec3 sample_geo = vec3(source, 1.0);
    // 초반에 강한 블러로 페이드인하고, 중반부터 원본으로 천천히 페이드아웃합니다.
    // 반동 구간은 위의 빠른 경로로 원래의 선명한 화면을 사용합니다.
    float blur_amount = smoothstep(0.0, 0.12, p)
        * (1.0 - smoothstep(0.3, 1.0, p));
    vec2 blur_radius = vec2(9.0) / (size * extent);
    vec4 before = resize_blur(niri_tex_prev, niri_geo_to_tex_prev, sample_geo, blur_radius, blur_amount);
    vec4 after = resize_blur(niri_tex_next, niri_geo_to_tex_next, sample_geo, blur_radius, blur_amount);
    vec4 color = mix(before, after, p);

    // 변형이 없는 시작·끝에는 기본 크로스페이드와 같은 렌더링으로 돌아갑니다.
    if (max(bend.x, bend.y) < 0.00001)
        return color;

    // config.kdl의 28px 둥근 모서리를 변형된 윤곽에도 적용합니다.
    float radius = min(28.0, min(size.x, size.y) * 0.5);
    vec2 q = abs((source - 0.5) * size) - (size * 0.5 - vec2(radius));
    float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
    float aa = 1.0 / min(extent.x, extent.y);
    float coverage = 1.0 - smoothstep(-aa, aa, distance);
    return color * coverage;
}
