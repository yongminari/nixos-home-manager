{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # [화면 캡처]
    grim
    slurp
    swappy
    
    # [알림]
    swaynotificationcenter
    libnotify
    
    # [하드웨어 제어]
    pamixer
    brightnessctl
    pavucontrol
    
    # [클립보드 및 기타]
    wl-clipboard
    networkmanagerapplet
  ];

  # Swappy 설정 (캡처 후 즉시 편집기)
  xdg.configFile."swappy/config".text = ''
    [Default]
    save_dir=${config.home.homeDirectory}/Pictures/Screenshots
    save_filename_format=swappy-%Y%m%d-%H%M%S.png
    show_panel=false
    line_size=5
    text_size=20
    text_font=sans-serif
    paint_mode=brush
    early_exit=false
    fill_shape=false
  '';

  # 스크린샷 폴더 자동 생성
  home.activation.createSwappyDir = config.lib.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${config.home.homeDirectory}/Pictures/Screenshots
  '';
}
