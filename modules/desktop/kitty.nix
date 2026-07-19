{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    font = {
      name = "Maple Mono NF";
      size = 12;
    };
    settings = {
      # 쉘 설정 (zsh)
      shell = "${pkgs.zsh}/bin/zsh";
      
      # 윈도우 레이아웃
      window_padding_width = 8;
      
      # 커서 흔적 효과 (Cursor Trail)
      cursor_trail = 3;
      cursor_trail_decay = "0.1 0.4";
      cursor_trail_start_threshold = 2;

      # 커서 깜빡임 애니메이션 (fade in/out 효과)
      cursor_blink_interval = "0.5 ease-in-out";
      
      # 타이틀바 비활성화
      hide_window_decorations = "yes";

      # 오디오 벨 끄기
      enable_audio_bell = "no";
      
      # 창 닫을 때 확인 비활성화
      confirm_os_window_close = 0;
      
      # 클립보드 제어 허용
      clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
    };
    extraConfig = ''
      # 모든 기본 단축키 비활성화
      clear_all_shortcuts yes

      # 복사 및 붙여넣기 (터미널 표준)
      map ctrl+shift+c copy_to_clipboard
      map ctrl+shift+v paste_from_clipboard

      # 폰트 크기 조절
      map ctrl+shift+equal change_font_size all +2.0
      map ctrl+shift+minus change_font_size all -2.0
      map ctrl+shift+backspace change_font_size all 0

      # 설정 파일 실시간 리로드 (기존 ctrl+shift+f5 -> ctrl+shift+,)
      map ctrl+shift+, load_config_file
    '';
    themeFile = "ayu";
  };
}
