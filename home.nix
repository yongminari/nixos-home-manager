{ config, pkgs, ... }:

{
  home.username = "yongminari";
  home.homeDirectory = "/home/yongminari";
  home.stateVersion = "25.11";
 
  programs.bash = {
    enable = true;
    initExtra = ''
      eval "$(fnm env --use-on-cd --shell bash)"
    '';
  };

  nixpkgs.config.allowUnfree = true; # Chrome 등 독점 소프트웨어 허용

  home.packages = with pkgs; [
    git
    vim
    fnm
    alacritty 
    ghostty
    niri
    fcitx5-hangul                 # 한글 입력 엔진 직접 추가
    qt6Packages.fcitx5-configtool # 설정 도구
    google-chrome                 # 크롬 브라우저 추가
    anyrun                        # 런처 추가
    maple-mono.NF                 # 영문 폰트
    d2coding                      # 한글 폰트
  ];

  fonts.fontconfig.enable = true;

  xdg.configFile."ghostty/config".text = ''
    font-family = "Maple Mono NF"
    font-family = "D2Coding"
    font-size = 12
  '';

  # anyrun 설정 파일을 직접 생성 (RON 형식)
  xdg.configFile."anyrun/config.ron".text = ''
    Config(
      x: Fraction(0.5),
      y: Fraction(0.3),
      width: Fraction(0.3),
      height: Absolute(0),
      hide_icons: false,
      ignore_exclusive_zones: false,
      layer: Overlay,
      hide_plugin_info: false,
      close_on_click: true,
      show_results_immediately: false,
      max_entries: None,
      plugins: [
        "${pkgs.anyrun}/lib/libapplications.so",
        "${pkgs.anyrun}/lib/libshell.so",
        "${pkgs.anyrun}/lib/libnix_run.so",
        "${pkgs.anyrun}/lib/libwebsearch.so",
      ],
    )
  '';

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GTK_IM_MODULE = "fcitx5";
    QT_IM_MODULE = "fcitx5";
    XMODIFIERS = "@im=fcitx5";
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "yongminari";
        email = "easyid21c@gmail.com";
      };
      init.defaultBranch = "main";
    };
  };

  programs.home-manager.enable = true;

  xdg.configFile."niri/config.kdl".text = ''
    input {
        keyboard {
            xkb {
                layout "us"
                options "ctrl:nocaps" // Caps Lock을 Ctrl로 변경
            }
        }
        touchpad {
            tap
            natural-scroll
        }
    }

    spawn-at-startup "fcitx5" "-d"

    binds {
        // niri 기본 단축키 도움말 (Mod+Shift+Slash)
        Mod+Shift+Slash { show-hotkey-overlay; }

        // 터미널 실행 (기본값인 alacritty 대신 ghostty 사용)
        Mod+T { spawn "ghostty"; }
        Mod+Return { spawn "ghostty"; }
        
        // 런처 실행 (anyrun)
        Mod+D { spawn "anyrun"; }
        Mod+Space { spawn "anyrun"; }

        // 창 닫기 및 niri 종료
        Mod+Shift+Q { close-window; }
        Mod+Shift+E { quit; }

        // 포커스 이동 (기본값)
        Mod+Left  { focus-column-left; }
        Mod+Down  { focus-window-down; }
        Mod+Up    { focus-window-up; }
        Mod+Right { focus-column-right; }
        Mod+H     { focus-column-left; }
        Mod+J     { focus-window-down; }
        Mod+K     { focus-window-up; }
        Mod+L     { focus-column-right; }

        // 창 이동 (기본값)
        Mod+Shift+Left  { move-column-left; }
        Mod+Shift+Down  { move-window-down; }
        Mod+Shift+Up    { move-window-up; }
        Mod+Shift+Right { move-column-right; }
        Mod+Shift+H     { move-column-left; }
        Mod+Shift+J     { move-window-down; }
        Mod+Shift+K     { move-window-up; }
        Mod+Shift+L     { move-column-right; }

        // 스크롤 및 레이아웃 (기본값)
        Mod+Page_Down      { focus-workspace-down; }
        Mod+Page_Up        { focus-workspace-up; }
        Mod+U              { focus-workspace-down; }
        Mod+I              { focus-workspace-up; }
        Mod+Shift+Page_Down { move-window-to-workspace-down; }
        Mod+Shift+Page_Up   { move-window-to-workspace-up; }
        Mod+Shift+U         { move-window-to-workspace-down; }
        Mod+Shift+I         { move-window-to-workspace-up; }

        Mod+WheelScrollDown      { focus-column-right; }
        Mod+WheelScrollUp        { focus-column-left; }
        Mod+Shift+WheelScrollDown { move-column-right; }
        Mod+Shift+WheelScrollUp   { move-column-left; }
    }
  '';
}
