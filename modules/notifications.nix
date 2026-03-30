{ config, pkgs, ... }:

{
  # SwayNotificationCenter Configuration
  xdg.configFile."swaync/config.json".text = ''
    {
      "$schema": "/etc/xdg/swaync/configSchema.json",
      "positionX": "right",
      "positionY": "top",
      "layer": "overlay",
      "control-center-margin-top": 10,
      "control-center-margin-bottom": 10,
      "control-center-margin-right": 10,
      "control-center-width": 400,
      "notification-icon-size": 64,
      "notification-body-image-height": 100,
      "notification-body-image-width": 200,
      "timeout": 10,
      "keyboard-shortcuts": true,
      "image-visibility": "always",
      "transition-time": 200,
      "hide-on-clear": false,
      "hide-on-touch": true,
      "widgets": [
        "title",
        "dnd",
        "notifications",
        "mpris"
      ],
      "widget-config": {
        "title": {
          "text": "Notifications",
          "clear-all-button": true,
          "button-text": "Clear All"
        },
        "dnd": {
          "text": "Do Not Disturb"
        },
        "mpris": {
          "image-size": 96,
          "image-radius": 12
        }
      }
    }
  '';

  # [SwayNC Style] - Catppuccin Mocha Royal Theme
  xdg.configFile."swaync/style.css".text = ''
    * {
      font-family: "Maple Mono NF", "D2Coding";
      font-weight: bold;
    }

    .notification-row { outline: none; }
    .notification-row:focus, .notification-row:hover { background: rgba(49, 50, 68, 0.5); }

    .notification {
      border-radius: 16px;
      margin: 10px;
      padding: 12px;
      box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
      border: 2px solid rgba(203, 166, 247, 0.4);
      background: #1e1e2e;
      color: #cdd6f4;
    }

    .notification-content { background: transparent; }
    .notification-title { color: #cba6f7; font-size: 1.1rem; }
    .notification-body { color: #bac2de; }

    .control-center {
      background: rgba(30, 30, 46, 0.9);
      border-radius: 20px;
      border: 2px solid #cba6f7;
      color: #cdd6f4;
      padding: 15px;
    }

    .widget-title > label { font-size: 1.5rem; color: #cba6f7; }
    .widget-title > button {
      background: #313244;
      color: #cdd6f4;
      border-radius: 10px;
      padding: 5px 10px;
    }

    .widget-dnd {
      background: #313244;
      padding: 10px;
      border-radius: 12px;
      margin: 10px 0;
    }
  '';
}
