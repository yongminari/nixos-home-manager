{ ... }:

{
  programs.bash = {
    enable = true;

    initExtra = ''
      source ${./shell-common.sh}

      # 컨테이너에서는 이후에 생성되는 호스트 전용 통합을 로드하지 않습니다.
      if is_container; then return; fi

      # [Welcome Message]
      if [[ $- == *i* ]] && command -v welcome-msg &>/dev/null; then welcome-msg; fi

      # [External Tools (fnm)]
      if command -v fnm &>/dev/null; then eval "$(fnm env --use-on-cd --shell bash)"; fi
    '';
  };
}
