{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    waybar
  ];

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
}
