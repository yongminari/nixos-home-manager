{ inputs, pkgs, config, lib, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia-shell = {
    enable = true;
    
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

      theme = {
      };

      # 배경화면 설정 (Wallhaven 온라인 소스 사용)
      wallpaper = {
        enabled = true;
        overviewEnabled = true;
        automationEnabled = true;
        wallpaperChangeMode = "random";
        randomIntervalSec = 300; # 5분
        
        # 오버뷰 시 블러 및 명암 효과
        overviewBlur = 0.5;
        overviewTint = 0.5;
        
        # Wallhaven 설정
        useWallhaven = true;
        wallhavenQuery = "dark";   # 어두운 배경화면 검색
        wallhavenCategories = "111"; # General, Anime, People 모두 포함
        wallhavenPurity = "100";     # SFW(Safe For Work) 이미지 전용
        wallhavenSorting = "random"; # 무작위 정렬
        
        # 전환 효과 설정
        transitionType = [
          "fade"
          "pixelate"
          "blur"
        ];
        transitionDuration = 1500;
      };

      colorSchemes.predefinedScheme = "Ayu";
    };
  };
}
