{ pkgs, ... }:

{
  # --- [Distrobox & Tools] ---
  home.packages = with pkgs; [
    distrobox
    podman-tui # Podman 관리용 TUI 도구 (선택 사항)
  ];
}
