{ config, pkgs, ... }:

let
  niri-focus-saver = pkgs.writeShellScriptBin "niri-focus-saver" ''
    ACTION=$1
    STATE_FILE="/tmp/niri-last-focus"

    if [ "$ACTION" = "save" ]; then
      WINDOW_ID=$(${pkgs.niri}/bin/niri msg --json focused-window 2>/dev/null | ${pkgs.jq}/bin/jq -r '.id // empty')
      OUTPUT_NAME=$(${pkgs.niri}/bin/niri msg --json outputs 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | .name // empty')
      
      echo "WINDOW_ID=$WINDOW_ID" > "$STATE_FILE"
      echo "OUTPUT_NAME=$OUTPUT_NAME" >> "$STATE_FILE"
    elif [ "$ACTION" = "restore" ]; then
      if [ -f "$STATE_FILE" ]; then
        source "$STATE_FILE"
        
        # 1. 윈도우 ID로 포커스 복원 시도
        if [ -n "$WINDOW_ID" ]; then
          ${pkgs.niri}/bin/niri msg action focus-window --id "$WINDOW_ID" 2>/dev/null
          if [ $? -eq 0 ]; then
            exit 0
          fi
        fi
        
        # 2. 윈도우 ID 복원이 실패했거나 없는 경우, 모니터(output) 이름으로 포커스 복원
        if [ -n "$OUTPUT_NAME" ]; then
          ${pkgs.niri}/bin/niri msg action focus-monitor "$OUTPUT_NAME" 2>/dev/null
        fi
      fi
    fi
  '';
in
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "${niri-focus-saver}/bin/niri-focus-saver save && ${config.programs.noctalia.package}/bin/noctalia msg session lock";
        unlock_cmd = "${niri-focus-saver}/bin/niri-focus-saver restore";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      };

      listener = [
        # [9분: 화면 어둡게 하기 (경고)]
        {
          timeout = 540;
          on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl set 10%";
          on-resume = "${pkgs.brightnessctl}/bin/brightnessctl set 100%";
        }
        # [10분: 화면 잠금 (Lock Screen)]
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        # [15분: 화면 끄기 (Power Off Monitors)]
        {
          timeout = 900;
          on-timeout = "${pkgs.niri}/bin/niri msg action power-off-monitors";
          on-resume = "${pkgs.niri}/bin/niri msg action power-on-monitors";
        }
      ];
    };
  };
}
