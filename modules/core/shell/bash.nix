{ ... }:

{
  programs.bash = {
    enable = true;

    initExtra = ''
      source ${./shell-common.sh}

      # [Welcome Message]
      if [[ $- == *i* ]] && command -v welcome-msg &>/dev/null; then welcome-msg; fi

      # [External Tools (fnm)]
      if command -v fnm &>/dev/null; then eval "$(fnm env --use-on-cd --shell bash)"; fi
    '';
  };
}
