{ config, pkgs, lib, osConfig, ... }:

let
  hasNvidiaGpu = lib.elem "nvidia" (osConfig.services.xserver.videoDrivers or []);
  btopPackage = if hasNvidiaGpu then
    pkgs.symlinkJoin {
      name = "btop-nvidia";
      paths = [ pkgs.btop ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/btop \
          --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
      '';
    }
  else
    pkgs.btop;
in {
  home.packages = with pkgs; [
    # [시스템 모니터링 및 정보]
    fastfetch
    jq

    # [파일 및 네트워크 유틸리티]
    ripgrep
    fd
    unzip
    lolcat
    dust               # 시각적 디스크 용량 분석
    tealdeer           # tldr (명령어 예제 사전)

    # [화면 캡처]
    grim
    slurp
    swappy
    
    # [알림]
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
    nix-tree           # Nix 의존성 트리 탐색
    sops               # Sops 암호화 편집 도구

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
    package = btopPackage;
    settings = {
      color_theme = "ayu";
      theme_background = false; # 투명 배경 사용
      vim_keys = true;
      update_ms = 500; # 업데이트 간격 (0.5초)
      show_gpu_info = "On";
    };
  };

  programs.nh = {
    enable = true;
    clean.enable = false; # nix.gc 설정을 명시적으로 사용하므로 비활성화
    # clean.extraArgs = "--keep-since 4d --keep 3";
  };

  # 사전 생성된 데이터베이스를 사용하는 nix-locate와 comma 래퍼
  programs.nix-index-database.comma.enable = true;

  # 클립보드 히스토리 감시 서비스
  services.cliphist.enable = true;
}
