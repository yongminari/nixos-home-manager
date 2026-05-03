# [Environment Detection]
function is_ssh() { [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" || -n "$SSH_CONNECTION" ]]; }
function is_container() { [[ -e /.dockerenv ]] || [[ -e /run/.containerenv ]] || [[ -n "$DISTROBOX_ENTER_PATH" ]] || grep -qE "docker|podman|containerd" /proc/1/cgroup 2>/dev/null; }
function is_vscode() { [[ -n "$VSCODE_IPC_HOOK_CLI" || -n "$VSCODE_PID" || "$TERM_PROGRAM" == "vscode" ]]; }

# [Container Error Shield]
if is_container; then
    # 1. 'alias' 명령어를 가로채서 안전한 기본값으로 교체
    function alias() {
        case "$1" in
            ls=*eza*)  builtin alias ls='ls --color=auto' ;;
            ll=*eza*)  builtin alias ll='ls -al --color=auto' ;;
            lt=*eza*)  builtin alias lt='ls -R --color=auto' ;;
            cat=*bat*) builtin alias cat='cat' ;;
            v=*nvim*)  builtin alias v='vi' ;;
            *)         builtin alias "$@" ;;
        esac
    }

    # 2. 초기 안전 별칭 설정
    builtin alias ls='ls --color=auto'
    builtin alias ll='ls -al --color=auto'
    builtin alias lt='ls -R --color=auto'

    # 3. 누락된 명령어들에 대한 더미(Dummy) 정의
    for cmd in atuin starship welcome-msg eza bat zoxide nvim; do
        if ! command -v "$cmd" &>/dev/null; then
            eval "$cmd() { :; }" 
        fi
    done
fi

# [Theme & Prompt Settings]
if is_ssh; then
  export STARSHIP_CONFIG="$HOME/.config/starship-ssh.toml"
elif is_container; then
  export STARSHIP_CONFIG="$HOME/.config/starship-docker.toml"
fi

# [Dynamic Aliases]
# 호스트 환경(컨테이너가 아닐 때)에서만 세련된 별칭들을 적용
if ! is_container; then
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
