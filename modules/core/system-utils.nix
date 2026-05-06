{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    # [시스템 모니터링 및 정보]
    htop
    fastfetch
    lsb-release
    jq

    # [파일 및 네트워크 유틸리티]
    ripgrep
    fd
    unzip
    lolcat
    rclone
    dust               # 시각적 디스크 용량 분석
    tealdeer           # tldr (명령어 예제 사전)

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
    # flake 경로는 home.sessionVariables.FLAKE에서 전역으로 관리하므로 여기서 생략하거나 변수화 가능
  };

  # 클립보드 히스토리 감시 서비스
  services.cliphist.enable = true;
}
