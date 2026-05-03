{ config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    google-chrome
    xwayland-satellite
  ];

  programs.alacritty = {
    enable = true;
    settings = {
      # Alacritty v0.13+ 최신 설정 사양 (general 섹션 사용)
      general = {
        import = [ "${inputs.alacritty-theme}/themes/ayu_dark.toml" ];
      };

      window = {
        opacity = 1.0;
        padding = { x = 12; y = 12; };
        dynamic_title = true;
      };

      font = {
        normal = { family = "Maple Mono NF"; style = "Regular"; };
        bold = { family = "Maple Mono NF"; style = "Bold"; };
        size = 12.0;
      };
    };
  };
}
