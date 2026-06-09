{ inputs, pkgs, config, lib, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  # Niri 기본 배경화면 파일을 유저 배경화면 디렉토리로 복사
  home.file."Pictures/Wallpapers/niri_wallpaper.jpg".source = ../desktop/niri/niri_wallpaper.jpg;

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
