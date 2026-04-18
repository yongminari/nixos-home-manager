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
        mode = "dark";
        # 절대 경로 대신 Nix path를 사용하여 이미지를 확실하게 참조합니다.
        wallpaper = ./niri/niri_wallpaper.jpg;
      };

      # 오버뷰(Overview) 배경화면 설정
      wallpaper = {
        enableOverviewWallpaper = true;
        blur = 20;
        dim = 0.5;
      };

      colorSchemes.predefinedScheme = "Ayu";
    };
  };
}
