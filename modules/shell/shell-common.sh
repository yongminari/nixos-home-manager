# [Environment Detection]
function is_ssh() { 
  [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" || -n "$SSH_CONNECTION" ]] || \
  [[ "$(ps -o comm= -p $PPID 2>/dev/null)" == "sshd" ]]
}
function is_docker() { [[ -e /.dockerenv ]] || grep -q "docker" /proc/1/cgroup 2>/dev/null; }
function is_vscode() { [[ -n "$VSCODE_IPC_HOOK_CLI" || -n "$VSCODE_PID" || "$TERM_PROGRAM" == "vscode" ]]; }

# [Theme & Prompt Settings]
# 환경에 따른 Starship 테마 전환 (로컬: Blue, SSH: Pink, Docker: Green)
if is_ssh; then
  export STARSHIP_CONFIG="$HOME/.config/starship-ssh.toml"
  # SSH 환경에서 백스페이스 오작동 방지를 위한 바인딩 (Ghostty/Zellij 대응)
  if [[ -n "$ZSH_VERSION" ]]; then
    bindkey "^?" backward-delete-char
    bindkey "^H" backward-delete-char
  fi
elif is_docker; then
  export STARSHIP_CONFIG="$HOME/.config/starship-docker.toml"
fi

# [SSH Wrapper]
# 다른 서버로 접속할 때 호환성을 위해 TERM 및 COLORTERM을 설정하여 전송
# Ghostty 사용 시 'ghostty +ssh'를 통해 terminfo 자동 주입 시도
ssh() {
  if [[ "$TERM" == "xterm-ghostty" || "$TERM_PROGRAM" == "Ghostty" ]]; then
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
