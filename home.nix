{ config, pkgs, ... }:

{
  imports = [
    ./modules/anyrun.nix
    ./modules/waybar.nix
    ./modules/niri.nix
  ];

  home.username = "yongminari";
  home.homeDirectory = "/home/yongminari";
  home.stateVersion = "25.11";
 
  programs.bash = {
    enable = true;
    initExtra = ''
      eval "$(fnm env --use-on-cd --shell bash)"
    '';
  };

  nixpkgs.config.allowUnfree = true; # Chrome 등 독점 소프트웨어 허용

  home.packages = with pkgs; [
    git
    vim
    fnm
    alacritty 
    ghostty
    fcitx5-hangul                 # 한글 입력 엔진 직접 추가
    qt6Packages.fcitx5-configtool # 설정 도구
    google-chrome                 # 크롬 브라우저 추가
    swaybg                        # 배경화면 도구 유지
    maple-mono.NF                 # 영문 폰트
    d2coding                      # 한글 폰트
  ];

  fonts.fontconfig.enable = true;

  xdg.configFile."ghostty/config".text = ''
    font-family = "Maple Mono NF"
    font-family = "D2Coding"
    font-size = 12
  '';

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    GTK_IM_MODULE = "fcitx5";
    QT_IM_MODULE = "fcitx5";
    XMODIFIERS = "@im=fcitx5";
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "yongminari";
        email = "easyid21c@gmail.com";
      };
      init.defaultBranch = "main";
    };
  };

  programs.home-manager.enable = true;
}
