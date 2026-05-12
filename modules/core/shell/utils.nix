{ config, pkgs, lib, ... }:

{
  home.shellAliases = {
    ls = "eza";
    ll = "eza -l --icons --git -a";
    lt = "eza --tree --level=2 --long --icons --git";
    cat = "bat";
    # Ghostty를 유지하면서 SSH 호환성을 챙기는 가장 현대적인 방법
    gssh = "ghostty +ssh";
    # ROS 2 & Qt Wayland compatibility fixes
    rviz2 = "env QT_QPA_PLATFORM=xcb rviz2";
    wireshark = "env QT_QPA_PLATFORM=xcb wireshark";

    # Common
    g = "git";
    v = "nvim";
    vi = "nvim";
    vim = "nvim";
    zj = "zellij";
    tocb = "wl-copy";
  };

  # Starship 프롬프트 (모든 쉘 통합)
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    settings = lib.importTOML ./starship.toml;
  };

  # Eza (ls 보조)
  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    icons = "auto";
    git = true;
  };

  # Zoxide (cd 대체)
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    options = [ "--cmd cd" ];
  };

  # Bat (cat 대체)
  programs.bat = {
    enable = true;
    config = { theme = "OneHalfDark"; };
  };

  # FZF
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # Direnv
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    nix-direnv.enable = true;
  };

  # Atuin (Magical Shell History)
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableNushellIntegration = true;
    flags = [ "--disable-up-arrow" ];
  };

  # Carapace (Multi-shell completion)
  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  # 공통 CLI 패키지
  home.packages = with pkgs; [
    htop
    fastfetch
    lolcat
    lsb-release
    python3
  ];

  # Starship SSH 설정 파일 연결
  xdg.configFile."starship-ssh.toml".source = ./starship-ssh.toml;
}
