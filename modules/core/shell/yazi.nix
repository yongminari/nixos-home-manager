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
          { name = "*.md"; run = "glow"; }
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
        rev = "main";
        sha256 = "sha256-o2EnQYOxp5bWn0eLn0sCUXcbtu6tbO9pdUdoquFCTVw=";
      };
      full-border = (pkgs.fetchFromGitHub {
        owner = "yazi-rs";
        repo = "plugins";
        rev = "1db18bb5a1c962f95873654a7af1202abb98da60";
        hash = "sha256-kcZGQB8Dfon8OipuAcNnCeRgTp/S0mQokADkuvEG4Lc=";
      }) + "/full-border.yazi";
      zoxide = (pkgs.fetchFromGitHub {
        owner = "yazi-rs";
        repo = "plugins";
        rev = "1db18bb5a1c962f95873654a7af1202abb98da60";
        hash = "sha256-kcZGQB8Dfon8OipuAcNnCeRgTp/S0mQokADkuvEG4Lc=";
      }) + "/zoxide.yazi";
      glow = pkgs.fetchFromGitHub {
        owner = "Reledia";
        repo = "glow.yazi";
        rev = "bd3eaa58c065eaf216a8d22d64c62d8e0e9277e9";
        hash = "sha256-mzW/ut/LTEriZiWF8YMRXG9hZ70OOC0irl5xObTNO40=";
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
        rev = "a83710153ab5625a64ef98d55e6ddad480a3756f";
        hash = "sha256-CPRVJVunBLwFLCoj+XfoIIwrrwHxqoElbskCXZgFraw=";
      };
      mediainfo = pkgs.fetchFromGitHub {
        owner = "boydaihungst";
        repo = "mediainfo.yazi";
        rev = "49f5ab722d617a64b3bea87944e3e4e17ba3a46b";
        hash = "sha256-PcGrFG06XiJYgBWq+c7fYsx1kjkCvIYRaBiWaJT+xkw=";
      };
    };
  };

  # Yazi 의존성 패키지
  home.packages = with pkgs; [
    glow
    ouch
    mediainfo
  ];
}
