{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # [Zsh Performance Tuning]
    localVariables = {
      ZSH_AUTOSUGGEST_USE_ASYNC = "1";
      ZSH_AUTOSUGGEST_MANUAL_REBIND = "1";
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = "20";
      ZSH_DISABLE_COMPFIX = "true"; # Distrobox/Nix 권한 경고 방지
    };

    envExtra = ''
      export PATH=$HOME/.local/bin:$PATH
      export ZSH_DISABLE_COMPFIX="true" 
    '';

    initContent = ''
      source ${./shell-common.sh}

      # [SSH/Zellij Specific Fixes]
      if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
        bindkey "^?" backward-delete-char
        bindkey "^H" backward-delete-char
      fi

      # [Welcome Message]
      if [[ $- == *i* ]] && command -v welcome-msg &>/dev/null; then welcome-msg; fi

      # [External Tools (fnm)]
      if command -v fnm &>/dev/null; then eval "$(fnm env --use-on-cd --shell zsh)"; fi

      # [Keybindings]
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down

      # [Final Cleanup for Containers]
      # 모든 자동 통합(zoxide, atuin 등)이 끝난 후 컨테이너라면 한 번 더 청소합니다.
      if is_container; then
        unalias ls ll lt cat v vi vim g z 2>/dev/null
        # zoxide 등이 주입한 함수나 별칭도 제거 시도
        unset -f z zi 2>/dev/null
      fi
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "history-substring-search" ];
    };

    shellAliases = {
      g  = "git";
      v  = "nvim";
    };
  };
}
