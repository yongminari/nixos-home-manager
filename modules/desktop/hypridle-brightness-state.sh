#!/usr/bin/env bash
# Included by writeShellApplication; keep independently runnable for regression checks.
set -euo pipefail

action="${1:-}"
runtime_dir="${XDG_RUNTIME_DIR:-}"
[[ -n "$runtime_dir" ]] || exit 0
state_file="$runtime_dir/hypridle-brightness"
umask 077
exec 9>"$state_file.lock"
flock 9

log() { printf 'hypridle-brightness: %s\n' "$*" >&2; }
number() { [[ "$1" =~ ^(0|[1-9][0-9]*)$ ]]; }

case "$action" in
  dim)
    # Never replace an outstanding original value with an already dimmed value.
    [[ ! -e "$state_file" ]] || exit 0
    info="$(brightnessctl --class=backlight --machine-readable info 2>/dev/null)" || exit 0
    IFS=, read -r device class current _percent maximum <<< "$info"
    [[ "$class" == backlight && -n "$device" ]] || exit 0
    number "$current" && number "$maximum" || exit 0
    target=$((maximum / 10))
    (( target >= 1 )) || target=1
    (( current > target )) || exit 0
    temporary_file="$(mktemp "$state_file.XXXXXX")"
    trap 'rm -f "$temporary_file"' EXIT
    printf '%s %s %s\n' "$device" "$current" "$target" > "$temporary_file"
    mv "$temporary_file" "$state_file"
    if brightnessctl --quiet --class=backlight --device="$device" set "$target"; then
      log "dimmed $device from $current to $target"
    else
      log "dimming failed; keeping recovery record"
    fi
    ;;
  restore)
    [[ -r "$state_file" ]] || exit 0
    read -r device previous target extra < "$state_file" || { log "unreadable recovery record; retained"; exit 0; }
    # Upgrade records left by the old single-value helper during activation.
    if number "$device" && [[ -z "$previous$target$extra" ]]; then
      previous="$device"
      info="$(brightnessctl --class=backlight --machine-readable info 2>/dev/null)" || exit 0
      IFS=, read -r device class current _percent maximum <<< "$info"
      number "$maximum" || exit 0
      target=$((maximum / 10))
      (( target >= 1 )) || target=1
    fi
    if [[ -z "$device" || -n "$extra" ]] || ! number "$previous" || ! number "$target"; then
      log "invalid recovery record; retained"
      exit 0
    fi
    # Retry briefly when a resumed device is not ready. Never block idle startup
    # permanently, and retain the record when all attempts fail.
    for attempt in 1 2 3; do
      if current="$(brightnessctl --class=backlight --device="$device" get 2>/dev/null)" && number "$current"; then
        if [[ "$current" != "$target" ]]; then
          rm -f "$state_file"
          log "$device already restored or changed manually ($current); cleared stale record"
          exit 0
        fi
        if brightnessctl --quiet --class=backlight --device="$device" set "$previous"; then
          if restored="$(brightnessctl --class=backlight --device="$device" get 2>/dev/null)" && [[ "$restored" == "$previous" ]]; then
            rm -f "$state_file"
            log "restored $device to $previous"
            exit 0
          fi
        fi
      fi
      if (( attempt < 3 )); then sleep 1; fi
    done
    log "restore failed for $device; keeping recovery record for next attempt"
    ;;
  *) exit 2 ;;
esac
