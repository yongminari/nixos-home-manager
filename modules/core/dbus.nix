{ pkgs, ... }:

{
  # 프로필과 개별 패키지 경로가 같은 서비스 파일을 가리킬 때 한 번만 등록합니다.
  # 검색 순서·서비스 목록·정책은 유지하며 다른 파일의 이름 충돌은 계속 경고합니다.
  # NixOS/nixpkgs#303078: upstream에서 해결되면 이 로컬 패치를 제거합니다.
  services.dbus.brokerPackage = pkgs.dbus-broker.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./dbus-same-service-file.patch ];
  });
}
