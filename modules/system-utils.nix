{ config, pkgs, lib, ... }:

let
  # 프로젝트 내 로컬 이미지를 기본 배경화면으로 지정
  defaultWallpaper = ./niri/niri_wallpaper.jpg;
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

    # [Nix 관리]
    nix-output-monitor # nh가 빌드 로그를 시각화할 때 사용
    nix-index          # 파일이 어떤 패키지에 있는지 검색 (nix-locate)
  ];

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "ayu";
      theme_background = false; # 투명 배경 사용
      vim_keys = true;
      update_ms = 500; # 업데이트 간격 (0.5초)
    };
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/yongminari/nixos-home-manager";
  };

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
  home.file."Pictures/Wallpapers/niri_wallpaper.jpg".source = defaultWallpaper;

  # 배경화면 폴더 자동 생성 (이미지가 없을 경우를 대비)
  home.activation.createWallpaperDir = config.lib.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${config.home.homeDirectory}/Pictures/Wallpapers
  '';

  # 스크린샷 폴더 자동 생성
  home.activation.createScreenshotDir = config.lib.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${config.home.homeDirectory}/Pictures/Screenshots
  '';
}
