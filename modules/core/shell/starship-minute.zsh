# 입력 중에는 항상 띠를 표시하고, 제출 시 같은 분의 중복 띠만 접습니다.
# Starship이 생성한 명령과 인자를 재사용해 오류 색상과 vi 모드를 유지합니다.
zmodload zsh/datetime
autoload -Uz add-zsh-hook add-zle-hook-widget

typeset -g _starship_minute_full_prompt=$PROMPT
typeset -g _starship_minute_short_prompt=${PROMPT/ prompt / module character }
typeset -g _starship_last_prompt_minute=''

_starship_minute_precmd() {
  PROMPT=$_starship_minute_full_prompt
}

_starship_minute_line_finish() {
  # 보조 프롬프트와 vared 등에서는 기본 편집 동작을 유지합니다.
  [[ $CONTEXT == start && $LASTWIDGET != *send-break ]] || return 0
  local prompt_minute
  strftime -s prompt_minute '%Y-%m-%d %H:%M %z' "$EPOCHSECONDS"

  if [[ $prompt_minute == $_starship_last_prompt_minute ]]; then
    PROMPT=$_starship_minute_short_prompt
  else
    PROMPT=$_starship_minute_full_prompt
  fi
  # 명령이 터미널 기록에 남기 전에 ZLE가 띠와 입력 줄을 다시 그립니다.
  zle .reset-prompt
  zle -R
  # 빈 입력에는 preexec가 호출되지 않으므로 제출 훅에서 기록합니다.
  _starship_last_prompt_minute=$prompt_minute
}

# Starship의 종료 코드 수집 이후 실행해야 합니다.
add-zsh-hook precmd _starship_minute_precmd
add-zle-hook-widget line-finish _starship_minute_line_finish
