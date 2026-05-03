{ pkgs, ... }:

{
  # --- [Container UI Tools] ---
  home.packages = with pkgs; [
    podman-tui # Podman 관리용 TUI 도구
  ];
}
