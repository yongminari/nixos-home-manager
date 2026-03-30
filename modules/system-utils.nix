{ config, pkgs, lib, ... }:

let
  # 기본 배경화면 다운로드 (Catppuccin Mocha 저녁 하늘 테마)
  defaultWallpaper = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/iruzo/wp/main/desktop-catppuccin-mocha-evening-sky.png";
    sha256 = "sha256-fYMzoY3un4qGOSR4DMqVUAFmGGil+wUze31rLLrjcAc=";
  };
in
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

  # 배경화면 이미지를 원하는 경로에 심볼릭 링크로 연결
  home.file."Pictures/Wallpapers/default_wallpaper.png".source = defaultWallpaper;

  # 스크린샷 폴더 자동 생성
  home.activation.createScreenshotDir = config.lib.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${config.home.homeDirectory}/Pictures/Screenshots
  '';
}
