{ config, pkgs, ... }:

{
  # --- [Container Engine (Podman)] ---
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # docker 명령어를 podman으로 연결
    defaultNetwork.settings.dns_enabled = true;
  };

  # Distrobox를 위해 필요한 추가 패키지 (시스템 레벨)
  environment.systemPackages = with pkgs; [
    distrobox
    fuse-overlayfs # 파일 시스템 레이어 지원
  ];

  # 사용자 계정을 podman 그룹에 추가 (이미 nixos-base에서 wheel 등에 추가되어 있지만 명시)
  users.users.yongminari.extraGroups = [ "podman" ];
}
