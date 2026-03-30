{ config, pkgs, ... }:

{
  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
        lock_cmd = pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock
        before_sleep_cmd = loginctl lock-session
    }

    # [9분: 화면 어둡게 하기 (경고)]
    listener {
        timeout = 540                                
        on-timeout = ${pkgs.brightnessctl}/bin/brightnessctl set 10%
        on-resume = ${pkgs.brightnessctl}/bin/brightnessctl set 100%
    }

    # [10분: 화면 잠금 (Lock Screen)]
    listener {
        timeout = 600                                
        on-timeout = loginctl lock-session
    }

    # [15분: 화면 끄기 (Power Off Monitors)]
    listener {
        timeout = 900                                
        on-timeout = ${pkgs.niri}/bin/niri msg action power-off-monitors
    }
  '';
}
