# [Environment Detection]
function is_ssh() { 
  [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" || -n "$SSH_CONNECTION" ]] && return 0
  [[ "$(ps -o comm= -p $PPID 2>/dev/null)" == "sshd" ]]
}
function is_vscode() { [[ "$TERM_PROGRAM" == "vscode" || -n "$VSCODE_IPC_HOOK_CLI" || -n "$VSCODE_PID" ]]; }

# [SSH Terminfo Fallback]
# SSH 접속 시 xterm-ghostty 정보를 모를 경우 xterm-256color로 fallback
if is_ssh; then
  # ~/.terminfo 경로를 우선 확인하도록 설정
  export TERMINFO_DIRS="$HOME/.terminfo:/usr/share/terminfo"
  
  if [[ "$TERM" == "xterm-ghostty" ]]; then
    # 시스템이 xterm-ghostty를 모르면 xterm-256color로 fallback
    if ! infocmp xterm-ghostty >/dev/null 2>&1; then
      export TERM=xterm-256color
    fi
    # SSH가 전달하지 않았을 COLORTERM을 명시적으로 선언 (256/Truecolor 활성화의 핵심)
    export COLORTERM=truecolor
  elif [[ "$TERM" == "xterm-kitty" ]]; then
    # 시스템이 xterm-kitty를 모르면 xterm-256color로 fallback
    if ! infocmp xterm-kitty >/dev/null 2>&1; then
      export TERM=xterm-256color
    fi
    export COLORTERM=truecolor
  fi
fi

# [SSH Prompt Settings]
if is_ssh; then
  export STARSHIP_CONFIG="$HOME/.config/starship-ssh.toml"
fi

# [Dynamic Aliases]
function try_alias() {
    local alias_name=$1
    local command_name=$2
    shift 2
    if command -v "$command_name" &>/dev/null; then
        alias "$alias_name"="$command_name $*"
    fi
}
try_alias ls eza
try_alias ll eza -l --icons --git -a
try_alias lt eza --tree --level=2 --icons --git
try_alias cat bat

# [SSH Wrapper]
# Ghostty 또는 Kitty 사용 시 terminfo 자동 주입 시도 (중첩 SSH 및 Zellij/Tmux 멀티플렉서 환경은 제외)
function ssh() {
  if [[ -z "$ZELLIJ" && -z "$TMUX" ]] && ! is_ssh && [[ "$TERM" == "xterm-ghostty" || "$TERM_PROGRAM" == "Ghostty" ]]; then
    ghostty +ssh "$@"
  elif [[ -z "$ZELLIJ" && -z "$TMUX" ]] && ! is_ssh && [[ "$TERM" == "xterm-kitty" || "$TERM_PROGRAM" == "kitty" ]]; then
    kitty +kitten ssh "$@"
  else
    TERM=xterm-256color COLORTERM=truecolor command ssh "$@"
  fi
}

# [Zellij Wrapper]
function zellij() {
  if is_ssh; then
    command zellij --config "$HOME/.config/zellij/remote.kdl" "$@"
  else
    command zellij "$@"
  fi
}

# [Zellij Auto-start]
if [[ $- == *i* ]] && [[ -z "$ZELLIJ" ]] && ! is_vscode && command -v zellij &>/dev/null; then
  parent_proc=$(ps -p $PPID -o comm= 2>/dev/null)
  if [[ "$parent_proc" != "zellij" ]]; then
    if is_ssh; then
      exec zellij --config "$HOME/.config/zellij/remote.kdl"
    else
      exec zellij
    fi
  fi
fi

# [GitLab CLI Configuration]
if [[ -f /run/secrets/gitlab_token ]]; then
  export GITLAB_TOKEN=$(cat /run/secrets/gitlab_token)
  export GITLAB_HOST="192.168.0.230"
fi
