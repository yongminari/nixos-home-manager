{ config, pkgs, ... }:

{
  # --- [Container Engine: Podman] ---
  # Distrobox는 Podman을 기본 엔진으로 사용하는 것을 권장합니다.
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # docker 명령어를 podman으로 사용할 수 있게 함
    defaultNetwork.settings.dns_enabled = true;
  };

  # --- [Distrobox & Tools] ---
  environment.systemPackages = with pkgs; [
    distrobox
    podman-tui # Podman 관리용 TUI 도구 (선택 사항)
  ];
}
