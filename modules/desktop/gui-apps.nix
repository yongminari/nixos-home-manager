{ config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    google-chrome
    xwayland-satellite
    obsidian
  ];

  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
      recolor = "false"; # 기본 색상 유지 (필요시 true로 변경하여 다크모드 가능)
    };
  };

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
