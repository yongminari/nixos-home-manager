{ config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    google-chrome
    ghostty
    xwayland-satellite
  ];

  programs.alacritty = {
    enable = true;
    settings = {
      # Alacritty v0.13+ 최신 설정 사양 (general 섹션 사용)
      general = {
        import = [ "${inputs.alacritty-theme}/themes/gruvbox_dark.toml" ];
      };

      window = {
        opacity = 0.95;
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

  # Ghostty 설정
  xdg.configFile."ghostty/config".text = ''
    # Ghostty 내장 테마 이름 (에러 방지를 위해 Gruvbox Dark로 수정)
    theme = Gruvbox Dark
    font-family = "Maple Mono NF"
    font-size = 12
    command = ${pkgs.zsh}/bin/zsh
  '';
}
