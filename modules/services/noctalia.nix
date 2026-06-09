{ inputs, pkgs, config, lib, ... }:

let
  fetchWallhaven = pkgs.writeShellScriptBin "fetch-wallhaven" ''
    mkdir -p ~/Pictures/Wallpapers
    API_URL="https://wallhaven.cc/api/v1/search?q=dark&categories=111&purity=100&sorting=random"
    IMAGE_URL=$(${pkgs.curl}/bin/curl -s "$API_URL" | ${pkgs.jq}/bin/jq -r '.data[0].path')
    
    if [ "$IMAGE_URL" != "null" ] && [ -n "$IMAGE_URL" ]; then
        FILENAME=$(basename "$IMAGE_URL")
        FILEPATH="$HOME/Pictures/Wallpapers/$FILENAME"
        ${pkgs.curl}/bin/curl -s -o "$FILEPATH" "$IMAGE_URL"
        # 현재 실행 중인 noctalia에 새 배경화면 적용
        ${config.programs.noctalia.package}/bin/noctalia msg wallpaper-set "$FILEPATH"
    fi
  '';
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  # Niri 기본 배경화면 파일을 유저 배경화면 디렉토리로 복사
  home.file."Pictures/Wallpapers/niri_wallpaper.jpg".source = ../desktop/niri/niri_wallpaper.jpg;

  home.packages = [
    fetchWallhaven
  ];

  # 주기적으로 새로운 배경화면을 Wallhaven에서 자동 수집하는 Systemd 타이머 등록
  systemd.user.services.fetch-wallhaven = {
    Unit = {
      Description = "Automatically fetch a new wallpaper from Wallhaven";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${fetchWallhaven}/bin/fetch-wallhaven";
      Type = "oneshot";
    };
  };

  systemd.user.timers.fetch-wallhaven = {
    Unit = {
      Description = "Timer to automatically fetch a new wallpaper from Wallhaven";
    };
    Timer = {
      OnUnitActiveSec = "10min"; # 10분마다 실행
      OnBootSec = "1min";        # 부팅 1분 후 첫 실행
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    
    # 기본 설정 (Matugen 기반으로 테마가 자동 생성되나 필요시 커스텀 가능)
    settings = {
      # Noctalia Shell의 설정 인터페이스(GUI)를 통해 변경한 내용을 
      # 나중에 여기에 복사하여 영구적으로 유지할 수 있습니다.
      bar = {
        position = "top";
        height = 36;
      };
      
      launcher = {
        # 앱 그리드 뷰 활성화 여부 등
        view = "grid";
      };

      # 테마 설정 (v5 규격)
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Ayu";
      };

      # 배경화면 설정 (v5 규격)
      wallpaper = {
        enabled = true;
        directory = "~/Pictures/Wallpapers";
        transition = [
          "fade"
          "pixelate"
          "blur"
        ];
        transition_duration = 1500;
        transition_on_startup = true;

        # 기본/초기 배경화면 경로 지정
        default = {
          path = "~/Pictures/Wallpapers/niri_wallpaper.jpg";
        };

        # 배경화면 변경 자동화 설정 (5분 주기)
        automation = {
          enabled = true;
          interval_minutes = 5;
          order = "random";
          recursive = true;
        };
      };

      # 오버뷰 시 블러 및 명암 효과 (v5 규격)
      backdrop = {
        enabled = true;
        blur_intensity = 0.5;
        tint_intensity = 0.5;
      };
    };
  };
}
