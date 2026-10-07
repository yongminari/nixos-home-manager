# Save the local terminal state before the SSH client switches to raw mode.
# Redirected commands must not reset the user's terminal or change their output.
tty_state=""
if [[ -t 0 && -t 1 ]]; then
  tty_state=$(stty -g < /dev/tty 2>/dev/null) || tty_state=""
fi

# Invoked by the EXIT trap, including signal-triggered exits.
# shellcheck disable=SC2329
restore_terminal() {
  local exit_status=$?
  trap - EXIT

  if [[ -n "$tty_state" ]]; then
    if (( exit_status != 0 )); then
      # A disconnected remote Zellij cannot restore keyboard/mouse modes.
      tput reset > /dev/tty 2>/dev/null || true
    fi
    stty "$tty_state" < /dev/tty 2>/dev/null || true
  fi

  exit "$exit_status"
}

trap 'restore_terminal' EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

if "$@"; then
  exit 0
else
  exit "$?"
fi
