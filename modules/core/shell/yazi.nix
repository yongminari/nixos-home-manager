{ pkgs, ... }:

let
  copyFiles = pkgs.writeShellApplication {
    name = "yazi-copy-files";
    runtimeInputs = [ pkgs.python3 pkgs.wl-clipboard ];
    text = ''
      python3 -c 'import pathlib, sys; sys.stdout.write("".join(pathlib.Path(p).absolute().as_uri() + "\r\n" for p in sys.argv[1:]))' "$@" |
        wl-copy --type text/uri-list
    '';
  };
in
{
  # Yazi (Terminal File Manager)
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
    shellWrapperName = "y";

    # GUI 파일 관리자에 붙여넣을 수 있도록 파일 URI와 Yazi 내부 yank를 함께 저장합니다.
    keymap.mgr.prepend_keymap = [
      {
        on = "y";
        run = [ "shell --block -- ${copyFiles}/bin/yazi-copy-files %s" "yank" ];
        desc = "Copy files to system clipboard and yank";
      }
    ];

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
