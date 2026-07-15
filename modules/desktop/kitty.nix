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
      
      # 타이틀바 비활성화
      hide_window_decorations = "yes";

      # 오디오 벨 끄기
      enable_audio_bell = "no";
      
      # 창 닫을 때 확인 비활성화
      confirm_os_window_close = 0;
      
      # 클립보드 제어 허용
      clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
    };
    themeFile = "ayu";
  };
}
