{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "yongminari";
        email = "easyid21c@gmail.com";
      };
      init.defaultBranch = "main";
      core.ignorecase = true;
    };
  };

  # Delta: Syntax-highlighted git pager
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      side-by-side = true;
      syntax-theme = "Dracula";
    };
  };

  # Lazygit Configuration
  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        log = {
          showGraph = "always";
        };
      };
    };
  };
}
