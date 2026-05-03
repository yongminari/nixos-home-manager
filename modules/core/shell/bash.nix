{ config, pkgs, lib, ... }:

{
  programs.bash = {
    enable = true;
    
    shellAliases = {
      # 컨테이너 환경에서 안전한 기본 별칭들만 남깁니다.
    };

    initExtra = ''
      source ${./shell-common.sh}

      # [Welcome Message]
      if [[ $- == *i* ]] && command -v welcome-msg &>/dev/null; then welcome-msg; fi

      # [External Tools (fnm)]
      if command -v fnm &>/dev/null; then eval "$(fnm env --use-on-cd --shell bash)"; fi

      # [Final Cleanup for Containers]
      if is_container; then
        unalias ls ll lt cat v vi vim g z cd 2>/dev/null
        unset -f z zi cd 2>/dev/null
      fi
    '';
  };
}
