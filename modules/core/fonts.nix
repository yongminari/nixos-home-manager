{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nerd-fonts.ubuntu-mono
    monaspace
    nerd-fonts.jetbrains-mono
  ];
}
