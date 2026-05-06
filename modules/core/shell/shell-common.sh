# [Environment Detection]
function is_ssh() { 
  [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" || -n "$SSH_CONNECTION" ]] && return 0
  [[ "$(ps -o comm= -p $PPID 2>/dev/null)" == "sshd" ]]
}
function is_container() {
    # Distrobox, Docker, Podman 등 컨테이너 환경 감지
    [[ -n "$DISTROBOX_ENTER_PATH" ]] || [[ -e /run/.containerenv ]] || [[ -e /.dockerenv ]] || grep -qE "docker|podman|containerd" /proc/1/cgroup 2>/dev/null
}
function is_vscode() { [[ "$TERM_PROGRAM" == "vscode" || -n "$VSCODE_IPC_HOOK_CLI" || -n "$VSCODE_PID" ]]; }

# [Container Error Shield]
# 컨테이너 환경에서 호스트 전용 도구들이 실행되어 에러가 발생하는 것을 방지
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

    # 3. 호스트 도구가 없을 경우를 대비한 더미(Dummy) 정의
    for cmd in atuin starship welcome-msg eza bat zoxide nvim; do
        if ! command -v "$cmd" &>/dev/null; then
            eval "$cmd() { :; }" 
        fi
    done
fi

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
  fi
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
# Ghostty 사용 시 'ghostty +ssh'를 통해 terminfo 자동 주입 시도 (중첩 SSH는 제외)
function ssh() {
  if ! is_ssh && [[ "$TERM" == "xterm-ghostty" || "$TERM_PROGRAM" == "Ghostty" ]]; then
    ghostty +ssh "$@"
  else
    TERM=xterm-256color COLORTERM=truecolor command ssh "$@"
  fi
}

# [Zellij Wrapper]
function zellij() {
  if is_ssh || is_container; then
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
