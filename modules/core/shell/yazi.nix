{ config, pkgs, inputs, ... }:

{
  # Yazi (Terminal File Manager)
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
    shellWrapperName = "y";

    keymap = {
      manager.prepend_keymap = [
        { on = [ "Z" ]; exec = "plugin zoxide"; desc = "Jump to a directory using zoxide"; }
      ];
    };

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
      plugin = {
        prepend_previewers = [
          { url = "*.md"; run = "rich-preview"; }
          { mime = "application/{*zip,tar,bzip2,7z*,rar,xz,zstd,java-archive}"; run = "ouch"; }
          { mime = "{image,audio,video}/*"; run = "mediainfo"; }
        ];
      };
    };

    initLua = ''
      require("githead"):setup()
      require("full-border"):setup()
      require("starship"):setup()
    '';

    plugins = {
      githead = pkgs.yaziPlugins.githead;
      full-border = pkgs.yaziPlugins.full-border;
      rich-preview = pkgs.yaziPlugins.rich-preview;
      ouch = pkgs.yaziPlugins.ouch;
      starship = pkgs.yaziPlugins.starship;
      mediainfo = pkgs.yaziPlugins.mediainfo;
    };
  };

  # Yazi 의존성 패키지
  home.packages = with pkgs; [
    rich-cli
    ouch
    mediainfo
  ];
}
