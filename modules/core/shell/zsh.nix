{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # [Zsh Performance Tuning]
    # 대용량 터미널 출력 및 SSH 환경에서도 부드러운 작동을 위해 비동기 모드 활성화
    localVariables = {
      ZSH_AUTOSUGGEST_USE_ASYNC = "1";
      ZSH_AUTOSUGGEST_MANUAL_REBIND = "1";
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = "20";
    };

    envExtra = ''
      export PATH=$HOME/.local/bin:$PATH
    '';

    # [Standard initContent]
    # builtins.readFile을 사용하여 shell-common.sh 내용을 직접 포함 (더 견고한 배포)
    initContent = ''
      ${builtins.readFile ./shell-common.sh}

      # [SSH/Zellij Specific Fixes]
      if [[ -n "$SSH_CLIENT" || -n "$SSH_TTY" ]]; then
        # SSH 환경에서 백스페이스 오작동 방지
        bindkey "^?" backward-delete-char
        bindkey "^H" backward-delete-char
      fi

      # [Welcome Message]
      if [[ $- == *i* ]]; then welcome-msg; fi

      # [External Tools (fnm)]
      if command -v fnm &>/dev/null; then eval "$(fnm env --use-on-cd --shell zsh)"; fi

      # [Keybindings]
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "history-substring-search" ];
    };

    shellAliases = {
      ls = "eza";
      ll = "eza -l --icons --git -a";
      lt = "eza --tree --level=2 --icons --git"; # Nushell과 동일하게 트리 뷰 제공
      cat = "bat";
      g  = "git";
      v  = "nvim";
    };
  };
}
