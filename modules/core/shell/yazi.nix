{ pkgs, ... }:

{
  # Yazi (Terminal File Manager)
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
    shellWrapperName = "y";

    settings = {
      mgr = {
        show_hidden = false;
        sort_by = "alphabetical";
      };
      opener = {
        edit = [
          { run = ''${pkgs.neovim}/bin/nvim %s''; block = true; }
        ];
      };
      plugin = {
        prepend_previewers = [
          { url = "*.md"; run = "rich-preview"; }
        ];
      };
    };

    initLua = ''
      require("full-border"):setup()
      require("starship"):setup()
    '';

    plugins = {
      full-border = pkgs.yaziPlugins.full-border;
      rich-preview = pkgs.yaziPlugins.rich-preview;
      starship = pkgs.yaziPlugins.starship;
    };

    extraPackages = [ pkgs.rich-cli ];
  };
}
