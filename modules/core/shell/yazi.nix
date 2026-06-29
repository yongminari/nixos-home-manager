{ config, pkgs, ... }:

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
      githead = pkgs.fetchFromGitHub {
        owner = "llanosrocas";
        repo = "githead.yazi";
        rev = "317d09f728928943f0af72ff6ce31ea335351202";
        sha256 = "sha256-o2EnQYOxp5bWn0eLn0sCUXcbtu6tbO9pdUdoquFCTVw=";
      };
      full-border = (pkgs.fetchFromGitHub {
        owner = "yazi-rs";
        repo = "plugins";
        rev = "39aaf6dc77e546fe7f7836f102a6c57f96d15365";
        hash = "sha256-rl8EA8aymVQU1296IVsEZ2WR9xBxQTYBK+VUCic/K3k=";
      }) + "/full-border.yazi";
      zoxide = (pkgs.fetchFromGitHub {
        owner = "yazi-rs";
        repo = "plugins";
        rev = "39aaf6dc77e546fe7f7836f102a6c57f96d15365";
        hash = "sha256-rl8EA8aymVQU1296IVsEZ2WR9xBxQTYBK+VUCic/K3k=";
      }) + "/zoxide.yazi";
      rich-preview = pkgs.fetchFromGitHub {
        owner = "AnirudhG07";
        repo = "rich-preview.yazi";
        rev = "7d616ad88498747b46124f32a35847324862cd83";
        hash = "sha256-KHmjff7tHFLkPqOs8IdWQ0mCliSZn/mIKYof+ulnddk=";
      };
      ouch = pkgs.fetchFromGitHub {
        owner = "ndtoan96";
        repo = "ouch.yazi";
        rev = "406ce6c13ec3a18d4872b8f64b62f4a530759b2c";
        hash = "sha256-14x/bD0aD9hXONaqQD8Dt7rLBCMq7bkVLH6uCPOQ0C8=";
      };
      starship = pkgs.fetchFromGitHub {
        owner = "Rolv-Apneseth";
        repo = "starship.yazi";
        rev = "159eaba5b5052bf78ff6cfbfe4e527b946818c82";
        hash = "sha256-I21to4cxlszRpsb58cvsmwX7VglQBSJC0rrsFIltzC8=";
      };
      mediainfo = pkgs.fetchFromGitHub {
        owner = "boydaihungst";
        repo = "mediainfo.yazi";
        rev = "a6d30a1c85faabe9bab215b83efb3c646b4c2924";
        hash = "sha256-s2/6ljln64oVbKVFTGbRdxB8x9ASCo7FKDvC65eyDWM=";
      };
    };
  };

  # Yazi 의존성 패키지
  home.packages = with pkgs; [
    rich-cli
    ouch
    mediainfo
  ];
}
