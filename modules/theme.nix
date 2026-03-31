{ config, pkgs, ... }:

{
  # GTK Theme Configuration
  gtk = {
    enable = true;
    
    # 1. 테마 설정 (Catppuccin Mocha)
    theme = {
      name = "catppuccin-mocha-mauve-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "mauve" ];
        size = "standard";
        tweaks = [ "rimless" "black" ];
        variant = "mocha";
      };
    };

    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.theme = null;

    # 2. 아이콘 설정 (Papirus-Dark)

    # 2. 아이콘 설정 (Papirus-Dark)
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    # 3. 커서 설정
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 48; # niri 환경에 적절한 크기로 조정
    };

    font = {
      name = "Maple Mono NF";
      size = 11;
    };
  };

  # Qt 앱들을 GTK 테마와 동기화
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";
  };

  # dconf 활성화
  dconf.enable = true;

  # dconf 설정으로 GNOME 환경의 커서 크기 강제 지정
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      cursor-size = 48;
      cursor-theme = "Bibata-Modern-Ice";
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
}
