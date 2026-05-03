# [Environment Detection]
function is_ssh() { 
  # 환경 변수를 우선 체크하여 99.9%의 경우 ps 호출 없이 빠르게 판별
  [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" || -n "$SSH_CONNECTION" ]]
}
function is_docker() { [[ -e /.dockerenv ]] || grep -q "docker" /proc/1/cgroup 2>/dev/null; }
function is_vscode() { [[ -n "$VSCODE_IPC_HOOK_CLI" || -n "$VSCODE_PID" || "$TERM_PROGRAM" == "vscode" ]]; }

# [Theme & Prompt Settings]
if is_ssh; then
  export STARSHIP_CONFIG="$HOME/.config/starship-ssh.toml"
elif is_docker; then
  export STARSHIP_CONFIG="$HOME/.config/starship-docker.toml"
fi

# [SSH Wrapper]
# Ghostty 사용 시 'ghostty +ssh'를 통해 terminfo 자동 주입 시도
function ssh() {
  if [[ ($TERM == "xterm-ghostty" || $TERM_PROGRAM == "Ghostty") && $# -gt 0 ]]; then
    ghostty +ssh "$@"
  else
    TERM=xterm-256color COLORTERM=truecolor command ssh "$@"
  fi
}

# [Zellij Wrapper]
function zellij() {
  if is_ssh || is_docker; then
    command zellij --config "$HOME/.config/zellij/remote.kdl" "$@"
  else
    command zellij "$@"
  fi
}

# [Zellij Auto-start]
if [[ $- == *i* ]] && [[ -z "$ZELLIJ" ]] && ! is_vscode; then
  parent_proc=$(ps -p $PPID -o comm= 2>/dev/null)
  if [[ "$parent_proc" != "zellij" ]]; then
    if is_ssh; then
      exec zellij --config "$HOME/.config/zellij/remote.kdl"
    else
      exec zellij
    fi
  fi
fi
