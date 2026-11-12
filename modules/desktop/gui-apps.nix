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
    bindings = {
      move_down_smooth = "j";
      move_up_smooth = "k";
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
