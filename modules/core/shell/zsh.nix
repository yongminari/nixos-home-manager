{ pkgs, ... }:

{
  home.packages = [
    pkgs.zsh-patina
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = false;

    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];

    # [Zsh Performance Tuning]
    localVariables = {
      ZSH_AUTOSUGGEST_USE_ASYNC = "1";
      ZSH_AUTOSUGGEST_MANUAL_REBIND = "1";
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = "20";
      ZSH_DISABLE_COMPFIX = "true"; # Distrobox/Nix 권한 경고 방지
    };

    envExtra = ''
      export ZSH_DISABLE_COMPFIX="true" 
    '';

    # [Zsh Initialization]
    # NOTE: 'initContent' is used as it is the modern/preferred option in this setup.
    initContent = ''
      source ${./shell-common.sh}

      # 컨테이너에서는 이후에 생성되는 호스트 전용 통합을 로드하지 않습니다.
      if is_container; then return; fi

      # [Completion Styling & Descriptions]
      zstyle ':completion:*' verbose yes
      zstyle ':completion:*:descriptions' format '[%d]'
      zstyle ':completion:*:messages' format ' %d'
      zstyle ':completion:*:warnings' format ' %d'
      zstyle ':completion:*' group-name ""

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

      # [zsh-patina Syntax Highlighting]
      eval "$(${pkgs.zsh-patina}/bin/zsh-patina activate)"
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "history-substring-search" ];
    };

    shellAliases = {
      # Custom Keyboard Guide
      keymap = "bat ~/nixos-home-manager/docs/keyboard-layout.md";

      # WireGuard Aliases
      vpn-on = "sudo systemctl start wg-quick-wg0";
      vpn-off = "sudo systemctl stop wg-quick-wg0";
      vpn-stat = "sudo wg";
    };
  };
}
