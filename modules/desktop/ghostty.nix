{ config, pkgs, ... }:

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
      window-decoration = "auto";
      background-opacity = 1.0;
      theme = "Ayu";

      # [Cursor]
      cursor-style = "block";
      cursor-style-blink = true;

      # [Cursor Shaders]
      custom-shader = [
        "${config.home.homeDirectory}/.config/ghostty/shaders/ripple_cursor.glsl"
        "${config.home.homeDirectory}/.config/ghostty/shaders/cursor_tail.glsl"
      ];
      custom-shader-animation = "always";

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

  # [Ghostty Cursor Shaders 자동 배포]
  home.file.".config/ghostty/shaders/ripple_cursor.glsl".source = ./shaders/ripple_cursor.glsl;
  home.file.".config/ghostty/shaders/cursor_tail.glsl".source = ./shaders/cursor_tail.glsl;
}
