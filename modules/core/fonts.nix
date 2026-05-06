{ pkgs, ... }:

{
  home.packages = with pkgs; [
    maple-mono.NF-unhinted
    d2coding
    nerd-fonts.ubuntu-mono
    monaspace
    nerd-fonts.jetbrains-mono
  ];
}
