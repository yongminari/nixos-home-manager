{ config, lib, osConfig, pkgs, ... }:

let
  isLaptop = (osConfig.networking.hostName or "") == "galaxy-book";

  niri-focus-saver = pkgs.writeShellApplication {
    name = "niri-focus-saver";
    runtimeInputs = with pkgs; [ coreutils jq niri ];
    text = ''
      action="''${1:-}"
      runtime_dir="''${XDG_RUNTIME_DIR:-}"

      if [[ -z "$runtime_dir" ]]; then
        exit 0
      fi

      state_file="$runtime_dir/niri-last-focus.json"

      case "$action" in
        save)
          umask 077
          window_id="$(niri msg --json focused-window 2>/dev/null | jq -r '.id // empty' || true)"
          output_name="$(niri msg --json focused-output 2>/dev/null | jq -r '.name // empty' || true)"
          temporary_file="$(mktemp "$runtime_dir/niri-last-focus.XXXXXX")"

          jq -n \
            --arg window_id "$window_id" \
            --arg output_name "$output_name" \
            '{ window_id: $window_id, output_name: $output_name }' \
            > "$temporary_file"
          mv "$temporary_file" "$state_file"
          ;;
        restore)
          if [[ ! -r "$state_file" ]]; then
            exit 0
          fi

          window_id="$(jq -r '.window_id // empty' "$state_file")"
          output_name="$(jq -r '.output_name // empty' "$state_file")"

          # 윈도우가 사라졌다면 기존 모니터로 포커스를 복원합니다.
          if [[ "$window_id" =~ ^[0-9]+$ ]] \
            && niri msg action focus-window --id "$window_id" >/dev/null 2>&1; then
            exit 0
          fi

          if [[ -n "$output_name" ]]; then
            niri msg action focus-monitor "$output_name" >/dev/null 2>&1 || true
          fi
          ;;
        *)
          exit 2
          ;;
      esac
    '';
  };

  brightness-state = pkgs.writeShellApplication {
    name = "hypridle-brightness-state";
    runtimeInputs = with pkgs; [ brightnessctl coreutils ];
    text = ''
      action="''${1:-}"
      runtime_dir="''${XDG_RUNTIME_DIR:-}"

      if [[ -z "$runtime_dir" ]]; then
        exit 0
      fi

      state_file="$runtime_dir/hypridle-brightness"

      case "$action" in
        dim)
          current="$(brightnessctl --class=backlight get 2>/dev/null)" || exit 0
          maximum="$(brightnessctl --class=backlight max 2>/dev/null)" || exit 0

          if [[ ! "$current" =~ ^[0-9]+$ || ! "$maximum" =~ ^[0-9]+$ ]]; then
            exit 0
          fi

          umask 077
          printf '%s\n' "$current" > "$state_file"

          target=$((maximum / 10))
          if (( target < 1 )); then
            target=1
          fi

          if (( current > target )); then
            brightnessctl --quiet --class=backlight set "$target"
          fi
          ;;
        restore)
          if [[ ! -r "$state_file" ]]; then
            exit 0
          fi

          read -r previous < "$state_file"
          rm -f "$state_file"

          if [[ "$previous" =~ ^[0-9]+$ ]]; then
            brightnessctl --quiet --class=backlight set "$previous" || true
          fi
          ;;
        *)
          exit 2
          ;;
      esac
    '';
  };
in
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "${niri-focus-saver}/bin/niri-focus-saver save || true; ${config.programs.noctalia.package}/bin/noctalia msg session lock";
        unlock_cmd = "${niri-focus-saver}/bin/niri-focus-saver restore";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      };

      listener = lib.optionals isLaptop [
        # [9분: 화면 어둡게 하기 (경고)]
        {
          timeout = 540;
          on-timeout = "${brightness-state}/bin/hypridle-brightness-state dim";
          on-resume = "${brightness-state}/bin/hypridle-brightness-state restore";
        }
      ] ++ [
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
