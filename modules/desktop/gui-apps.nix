{ config, pkgs, inputs, osConfig ? {}, ... }:

{
  home.packages = with pkgs; [
    (if (osConfig.networking.hostName or "") == "ai-x1-pro" then
      (google-chrome.override {
        commandLineArgs = [
          "--ozone-platform=wayland"
          "--enable-features=WaylandWindowDecorations"
        ];
      })
     else
      google-chrome)
    obsidian
    geeqie
    onlyoffice-desktopeditors
  ];

  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
      recolor = "false"; # 기본 색상 유지 (필요시 true로 변경하여 다크모드 가능)
    };
  };
}
