autoload -Uz add-zsh-hook add-zle-hook-widget

typeset -g _starship_full_prompt=$PROMPT
typeset -g _starship_character_prompt=${PROMPT/ prompt / module character }
typeset -g _starship_prompt_band=''
typeset -g _starship_previous_band=''

_starship_snapshot_precmd() {
  # 로컬·SSH 형식 모두 마지막 줄은 character입니다. 위쪽 띠만 고정하고
  # 입력 기호는 vi 모드 전환과 직전 명령의 종료 상태를 계속 반영합니다.
  local rendered=${(e)_starship_full_prompt}
  _starship_prompt_band=${rendered%$'\n'*}
  PROMPT='${_starship_prompt_band}'$'\n'${_starship_character_prompt}
}

_starship_snapshot_line_finish() {
  [[ $CONTEXT == start && $LASTWIDGET != *send-break ]] || return 0
  if [[ $_starship_prompt_band == "$_starship_previous_band" ]]; then
    PROMPT=$_starship_character_prompt
    zle .reset-prompt
    zle -R
  else
    # 빈 Enter라도 새 띠가 처음 기록된 위치를 보존합니다.
    _starship_previous_band=$_starship_prompt_band
  fi
}

add-zsh-hook precmd _starship_snapshot_precmd
add-zle-hook-widget line-finish _starship_snapshot_line_finish
