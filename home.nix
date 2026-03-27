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
    anyrun                        # 다시 anyrun으로 복귀
    waybar                        # 상태바 유지
    swaybg                        # 배경화면 도구 유지
    maple-mono.NF                 # 영문 폰트
    d2coding                      # 한글 폰트
  ];

  # anyrun 설정 (검증된 플러그인 경로 사용)
  xdg.configFile."anyrun/config.ron".text = ''
    Config(
      x: Fraction(0.5),
      y: Fraction(0.3),
      width: Fraction(0.3),
      height: Absolute(0),
      hide_icons: false,
      ignore_exclusive_zones: false,
      layer: Overlay,
      hide_plugin_info: true,
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

  fonts.fontconfig.enable = true;

  xdg.configFile."ghostty/config".text = ''
    font-family = "Maple Mono NF"
    font-family = "D2Coding"
    font-size = 12
  '';

  # Waybar 설정 (V5.e 테마 기반 및 niri 최적화)
  xdg.configFile."waybar/config".text = ''
    {
      "layer": "top",
      "position": "top",
      "height": 34,
      "spacing": 4,
      "margin-top": 5,
      "margin-left": 10,
      "margin-right": 10,
      
      "modules-left": ["group/left1", "niri/window"],
      "modules-center": ["niri/workspaces"],
      "modules-right": ["tray", "backlight", "pulseaudio", "network", "battery", "clock"],

      "group/left1": {
        "orientation": "horizontal",
        "modules": [
          "custom/launcher",
          "cpu",
          "memory"
        ]
      },

      "custom/launcher": {
        "format": "󱄅",
        "on-click": "anyrun",
        "tooltip": false
      },

      "niri/workspaces": {
        "format": "{icon}",
        "format-icons": {
          "active": "",
          "default": ""
        }
      },

      "niri/window": {
        "format": "󱂬 {title}",
        "max-length": 40
      },

      "clock": {
        "format": "{:%H:%M}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
      },

      "cpu": {
        "format": " {usage}%",
        "interval": 2
      },

      "memory": {
        "format": " {used:0.1f}G",
        "interval": 2
      },

      "backlight": {
        "format": "{icon} {percent}%",
        "format-icons": ["🌑", "🌘", "🌗", "🌖", "🌕"]
      },

      "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": "",
        "format-icons": {
          "default": ["", "", ""]
        }
      },

      "network": {
        "format-wifi": " {essid}",
        "format-ethernet": "󰈀",
        "format-disconnected": "󰤮",
        "tooltip-format": "{ifname} via {gwaddr}"
      },

      "battery": {
        "states": {
          "warning": 20,
          "critical": 10
        },
        "format": "{icon} {capacity}%",
        "format-charging": "󰂄 {capacity}%",
        "format-icons": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
      },

      "tray": {
        "icon-size": 16,
        "spacing": 10
      }
    }
  '';

  xdg.configFile."waybar/style.css".text = ''
    /* V5.e 스타일 재해석 (Catppuccin Mocha Colors) */
    @define-color base #1e1e2e;
    @define-color surface #313244;
    @define-color text #cdd6f4;
    @define-color blue #89b4fa;
    @define-color pink #f5c2e7;

    * {
        font-family: "Maple Mono NF", "D2Coding";
        font-size: 13px;
        border: none;
        border-radius: 0;
    }

    window#waybar {
        background: transparent;
    }

    #waybar > box {
        background-color: alpha(@base, 0.85);
        border: 1px solid alpha(@blue, 0.3);
        border-radius: 12px;
        margin: 2px 0;
        padding: 2px 10px;
        box-shadow: 0 4px 10px rgba(0, 0, 0, 0.5);
    }

    #workspaces {
        margin: 4px;
        background-color: alpha(@surface, 0.5);
        border-radius: 8px;
    }

    #workspaces button {
        color: @text;
        padding: 0 8px;
        transition: all 0.3s ease;
    }

    #workspaces button.active {
        color: @blue;
        font-weight: bold;
    }

    #custom-launcher {
        font-size: 18px;
        color: @blue;
        margin-right: 10px;
    }

    #window, #clock, #cpu, #memory, #backlight, #pulseaudio, #network, #battery, #tray {
        background-color: alpha(@surface, 0.3);
        padding: 0 10px;
        margin: 4px 2px;
        border-radius: 6px;
        color: @text;
    }

    #clock {
        color: @pink;
        font-weight: bold;
    }

    #battery.warning { color: #fab387; }
    #battery.critical { color: #f38ba8; }
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

    // 창 규칙
    window-rule {
        geometry-corner-radius 12
        clip-to-geometry true
    }

    spawn-at-startup "fcitx5" "-d"
    spawn-at-startup "waybar"
    // 배경화면 설정 (원하는 이미지 경로로 수정하세요)
    // spawn-at-startup "swaybg" "-i" "/path/to/your/wallpaper.jpg" "-m" "fill"

    binds {
        // niri 기본 단축키 도움말 (Mod+Shift+Slash)
        Mod+Shift+Slash { show-hotkey-overlay; }

        // 터미널 실행
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
