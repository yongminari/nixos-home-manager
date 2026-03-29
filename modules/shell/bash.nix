{ config, pkgs, lib, ... }:

{
  programs.bash = {
    enable = true;
    
    shellAliases = {
      ls = "eza";
      ll = "eza -l --icons --git -a";
      lt = "eza --tree --level=2 --long --icons --git";
      cat = "bat";
    };

    initExtra = ''
      source ${./shell-common.sh}

      # [Welcome Message]
      if [[ $- == *i* ]]; then welcome-msg; fi

      # [External Tools (fnm)]
      if command -v fnm &>/dev/null; then eval "$(fnm env --use-on-cd --shell bash)"; fi
    '';
  };
}
