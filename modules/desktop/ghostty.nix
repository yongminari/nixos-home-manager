{ config, pkgs, inputs, ... }:

{
  programs.ghostty = {
    enable = true;
    # [셸 통합 활성화] - 새 탭 작업 디렉토리 유지 등의 기능을 위해 활성화
    enableZshIntegration = true;
    enableBashIntegration = true;

    # [Ghostty 설정] - Nix 속성 세트 방식으로 정의
    settings = {
      # SSH 접속 시 원격 서버에 terminfo를 자동으로 주입하기 위해 xterm-ghostty 사용
      term = "xterm-ghostty";
      command = "${pkgs.zsh}/bin/zsh";
      
      # [Font]
      font-family = [
        "Maple Mono NF"
        "D2Coding ligature"
      ];
      font-size = 12;

      # [Window & Visuals]
      window-decoration = "none";
      theme = "Ayu";
      background-opacity = 1.0;

      # [Process & Shutdown Tune]
      # 마지막 창이 닫힐 때 확실하게 프로세스를 종료하여 종료 시 systemd hang(2분 대기) 현상을 방지합니다.
      quit-after-last-window-closed = true;

      # [Cursor]
      cursor-style = "block";
      cursor-style-blink = true;

      # [Cursor & Effect Shaders]
      # 여러 셰이더를 체이닝하여 동시에 쓸 수 있지만, 화면 전체 셰이더와 커서 셰이더를 과도하게 조합하면 
      # GPU 부하가 늘어나 출력이 씹히거나 느려질 수 있습니다.
      custom-shader = [
        # -- A. 화면 전체 및 테두리 이펙트 (원하는 것 하나만 주석 해제하여 사용 추천) --
        # "${config.home.homeDirectory}/.config/ghostty/shaders/aurora.glsl" # 오로라 테두리 네온 효과
        # "${config.home.homeDirectory}/.config/ghostty/shaders/bettercrt.glsl" # 깔끔한 레트로 CRT 필터
        # "${config.home.homeDirectory}/.config/ghostty/shaders/crt.glsl" # 강한 빈티지 CRT 곡률/스캔라인 필터

        # -- B. 커서 이펙트 (기존 물결 및 트레일 효과) --
        "${config.home.homeDirectory}/.config/ghostty/shaders/ripple_cursor.glsl"
        "${config.home.homeDirectory}/.config/ghostty/shaders/cursor_tail.glsl"
      ];

      # [Shader Animation Performance Tune]
      # "always"로 두면 백그라운드에서도 GPU를 지속 점유하여 터미널 렌더링 지연(출력 리프레시 밀림) 및
      # 종료 시 행(hang)을 유발하므로 비활성화(기본값: 창 포커스 시에만 렌더링)하는 것을 권장합니다.
      # custom-shader-animation = "always";

      # [Shell Integration]
      shell-integration = "detect";
      shell-integration-features = "no-cursor,ssh-terminfo";

      # [Clipboard]
      clipboard-read = "allow";
      clipboard-write = "allow";

      # [Keybinds] - 요청하신 특정 단축키 비활성화
      keybind = [
        # [텍스트 선택 및 조정]
        "ctrl+shift+a=unbind"
        "shift+arrow_left=unbind"
        "shift+arrow_right=unbind"
        "shift+arrow_up=unbind"
        "shift+arrow_down=unbind"

        # [탭 관리]
        "ctrl+shift+t=unbind"
        "ctrl+shift+w=unbind"
        "ctrl+tab=unbind"
        "ctrl+shift+tab=unbind"
        "ctrl+shift+arrow_left=unbind"
        "ctrl+shift+arrow_right=unbind"
        "ctrl+page_up=unbind"
        "ctrl+page_down=unbind"

        # [특정 번호 탭 이동]
        "alt+1=unbind"
        "alt+2=unbind"
        "alt+3=unbind"
        "alt+4=unbind"
        "alt+5=unbind"
        "alt+6=unbind"
        "alt+7=unbind"
        "alt+8=unbind"
        "alt+9=unbind"
        "alt+digit_1=unbind"
        "alt+digit_2=unbind"
        "alt+digit_3=unbind"
        "alt+digit_4=unbind"
        "alt+digit_5=unbind"
        "alt+digit_6=unbind"
        "alt+digit_7=unbind"
        "alt+digit_8=unbind"

        # [화면 분할 및 이동]
        "ctrl+shift+o=unbind"
        "ctrl+shift+e=unbind"
        "ctrl+alt+arrow_up=unbind"
        "ctrl+alt+arrow_down=unbind"
        "ctrl+alt+arrow_left=unbind"
        "ctrl+alt+arrow_right=unbind"

        # [검색]
        "ctrl+shift+f=unbind"
      ];
    };
  };

  # [GNOME 런처 인식 문제 해결]
  home.file.".local/share/applications/com.mitchellh.ghostty.desktop".source = 
    "${pkgs.ghostty}/share/applications/com.mitchellh.ghostty.desktop";

  # [Ghostty Cursor & Effect Shaders 자동 배포]
  home.file.".config/ghostty/shaders/ripple_cursor.glsl".source = ./shaders/ripple_cursor.glsl;
  home.file.".config/ghostty/shaders/cursor_tail.glsl".source = ./shaders/cursor_tail.glsl;
  home.file.".config/ghostty/shaders/aurora.glsl".source = "${inputs.ghostty-aurora}/aurora.glsl";
  home.file.".config/ghostty/shaders/bettercrt.glsl".source = "${inputs.ghostty-shaders}/bettercrt.glsl";
  home.file.".config/ghostty/shaders/crt.glsl".source = "${inputs.ghostty-shaders}/crt.glsl";
}
