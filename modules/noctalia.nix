{ inputs, pkgs, ... }:

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
        # 기본적으로 Catppuccin 스타일이나 매끈한 다크 테마를 따릅니다.
        mode = "dark";
        name = "ayu";
      };
    };
  };
}
