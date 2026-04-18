{ config, pkgs, ... }:

{
  # GTK Theme Configuration
  gtk = {
    enable = true;
    
    # 1. 테마 설정 (Ayu Dark)
    theme = {
      name = "Ayu-Dark";
      package = pkgs.ayu-theme-gtk;
    };

    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.theme = null;

    # 2. 아이콘 설정 (Papirus-Dark)
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    # 3. 커서 설정
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 48;
    };

    font = {
      name = "Maple Mono NF";
      size = 11;
    };
  };

  # 아이콘 테마 및 필수 테마 관련 패키지 명시적 추가
  home.packages = with pkgs; [
    papirus-icon-theme
    adwaita-icon-theme
    hicolor-icon-theme
  ];

  # Qt 앱들을 GTK 테마와 동기화
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "kvantum";
  };

  # dconf 활성화
  dconf.enable = true;

  # dconf 설정으로 GNOME 환경의 아이콘 및 커서 테마 지정
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      cursor-size = 48;
      cursor-theme = "Bibata-Modern-Ice";
      icon-theme = "Papirus-Dark";
      gtk-theme = "Ayu-Dark";
    };
  };

  # 커서 테마를 시스템 전반에 적용
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 48;
  };

  # 커서 테마 강제 연결 (Legacy 및 XWayland 호환성)
  home.file.".icons/default/index.theme".text = ''
    [icon theme]
    Inherits=Bibata-Modern-Ice
  '';

  # 테마 관련 세션 변수
  home.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "48";
    GTK_CURSOR_SIZE = "48";
  };
}
