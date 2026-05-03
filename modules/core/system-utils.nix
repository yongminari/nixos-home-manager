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
    cliphist           # 클립보드 히스토리 관리
    networkmanagerapplet

    # [Nix 관리]
    nix-output-monitor # nh가 빌드 로그를 시각화할 때 사용
    nix-index          # 파일이 어떤 패키지에 있는지 검색 (nix-locate)
    comma              # 임시 패키지 실행 ( , 명령어 )
    nix-tree           # Nix 의존성 트리 탐색

    # [추가 유틸리티]
    dust               # 시각적 디스크 용량 분석
    tealdeer           # tldr (명령어 예제 사전)
    procs              # ps 대체
    gping              # 비주얼 핑
  ];

  # wlogout 설정 (세련된 종료 메뉴)
  programs.wlogout = {
    enable = true;
    layout = [
      {
        label = "lock";
        action = "loginctl lock-session";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "logout";
        action = "niri msg action quit";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
    ];
  };

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

  # 스크린샷 폴더 자동 생성
  home.activation.createScreenshotDir = config.lib.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${config.home.homeDirectory}/Pictures/Screenshots
  '';

  # 클립보드 히스토리 감시 서비스
  services.cliphist.enable = true;

  # warpd 설정 (키보드 마우스 제어)
  xdg.configFile."warpd/config".text = ''
    # 기본 이동을 HJKL로 설정
    up: k
    down: j
    left: h
    right: l

    # 속도 및 가속도 조절 (더 정밀하게)
    speed: 500
    max_speed: 1200
    acceleration: 700
    decelerator_speed: 50
    decelerator: d

    # 힌트 모드 설정
    hint_chars: abcdefghijklmnopqrstuvwxyz
    hint_size: 20
    hint_bgcolor: #282c34
    hint_fgcolor: #abb2bf
    hint_border_radius: 4

    # 드래그/클릭 설정 (m:좌, ,:우, .:휠)
    buttons: m , .
    drag: v
  '';

  # warpd를 안정적으로 실행하기 위한 systemd 서비스
  systemd.user.services.warpd = {
    Unit = {
      Description = "warpd - Keyboard mouse emulation";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.warpd}/bin/warpd -f";
      Restart = "on-failure";
      RestartSec = "3s"; # 너무 빨리 재시작해서 start-limit-hit 걸리는 것 방지
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
