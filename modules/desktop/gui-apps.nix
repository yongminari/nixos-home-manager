{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    (if config.local.desktop.chromeArgs == [] then google-chrome else
      google-chrome.override { commandLineArgs = config.local.desktop.chromeArgs; })
    obsidian
    geeqie
    libreoffice
  ];

  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
      recolor = "false"; # 기본 색상 유지 (필요시 true로 변경하여 다크모드 가능)
    };
  };
}
