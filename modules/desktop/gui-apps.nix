{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    (if config.local.desktop.chromeArgs == [] then google-chrome else
      google-chrome.override { commandLineArgs = config.local.desktop.chromeArgs; })
    obsidian
    geeqie
    libreoffice
  ];

  programs.sioyek = {
    enable = true;
    config.move_screen_ratio = "1.0";
    # Zathura 기본 키에 대응합니다. 차이점은 docs/sioyek-guide.md 참고.
    bindings = {
      move_down = [ "j" "<down>" ];
      move_up = [ "k" "<up>" ];
      move_left = [ "h" "<left>" ];
      move_right = [ "l" "<right>" ];
      next_page = [ "J" "<pagedown>" ];
      previous_page = [ "K" "<pageup>" ];
      screen_down = [ "<C-f>" "<space>" ];
      screen_up = [ "<C-b>" "<S-<space>>" ];
      "setconfig_move_screen_ratio(0.5);screen_down;setconfig_move_screen_ratio(1.0)" = "<C-d>";
      "setconfig_move_screen_ratio(0.5);screen_up;setconfig_move_screen_ratio(1.0)" = "<C-u>";
      goto_beginning = "gg";
      goto_end = "G";
      goto_top_of_page = [ "H" "P" ];
      goto_bottom_of_page = "L";
      prev_state = "<C-o>";
      next_state = "<C-i>";
      escape = "<C-c>";

      fit_to_page_smart = "a";
      fit_to_page_width = "s";
      search = "/";
      next_item = "n";
      previous_item = "N";
      open_document = [ "o" "O" ];
      open_link = "f";
      copy_link = "c";
      command = ":";
      rotate_clockwise = "r";
      toggle_dark_mode = "<C-r>";
      reload = "R";
      goto_toc = "<tab>";
      toggle_two_page_mode = "d";
      toggle_presentation_mode = "<f5>";
      toggle_fullscreen = "<f11>";
      toggle_statusbar = "<C-n>";
      zoom_in = [ "+" "zI" ];
      zoom_out = [ "-" "zO" ];
      set_mark = "m";
      goto_mark = "'";
      quit = "q";

      # 직접 대응하지 않는 키가 Sioyek의 다른 기본 동작을 실행하지 않게 합니다.
      noop = [ "t" "y" "<C-t>" "<C-y>" "<C-j>" "<C-k>" "<C-m>" "?" "F" "D" "=" "z0" ];
      # 기존 h/l/O/P 기능은 Alt 조합으로 옮깁니다.
      add_highlight = "<A-h>";
      overview_definition = "<A-l>";
      open_prev_doc = "<A-o>";
      edit_portal = "<A-p>";
      copy = "<C-S-c>";
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "sioyek.desktop" ];
      "text/html" = [ "google-chrome.desktop" ];
      "x-scheme-handler/http" = [ "google-chrome.desktop" ];
      "x-scheme-handler/https" = [ "google-chrome.desktop" ];
      "x-scheme-handler/about" = [ "google-chrome.desktop" ];
      "x-scheme-handler/unknown" = [ "google-chrome.desktop" ];
    };
  };
}
