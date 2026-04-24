{ config, pkgs, lib, ... }:

{
  # Starship 프롬프트 (모든 쉘 통합)
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    settings = lib.importTOML ./starship.toml;
  };

  # Eza (ls 보조)
  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    icons = "auto";
    git = true;
  };

  # Zoxide (cd 대체)
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    options = [ "--cmd cd" ];
  };

  # Bat (cat 대체)
  programs.bat = {
    enable = true;
    config = { theme = "OneHalfDark"; };
  };

  # FZF
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # Direnv
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    nix-direnv.enable = true;
  };

  # Yazi (Terminal File Manager)
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
    shellWrapperName = "y";

    settings = {
      manager = {
        show_hidden = false;
        sort_by = "alphabetical";
        linemode = "githead";
      };
      status = {
        left = [
          { name = "hovered"; collect = false; }
          { name = "count"; collect = false; }
          { name = "githead"; collect = false; }
        ];
        right = [
          { name = "cursor"; collect = false; }
          { name = "sort"; collect = false; }
          { name = "permissions"; collect = false; }
        ];
      };
      opener = {
        edit = [
          { run = ''${pkgs.neovim}/bin/nvim "$@"''; block = true; }
        ];
      };
    };

    initLua = ''
      require("githead"):setup()
    '';

    plugins = {
      githead = pkgs.fetchFromGitHub {
        owner = "llanosrocas";
        repo = "githead.yazi";
        rev = "main";
        sha256 = "sha256-o2EnQYOxp5bWn0eLn0sCUXcbtu6tbO9pdUdoquFCTVw=";
      };
    };
  };

  # Carapace (Multi-shell completion)
  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  # Atuin (Magical Shell History)
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
    flags = [ "--disable-up-arrow" ];
  };

  # 공통 CLI 패키지
  home.packages = with pkgs; [
    htop
    fastfetch
    lolcat
    lsb-release
    python3
  ];

  # Starship SSH 설정 파일 연결
  xdg.configFile."starship-ssh.toml".source = ./starship-ssh.toml;
}
