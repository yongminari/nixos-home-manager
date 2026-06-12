{ config, pkgs, username, ... }:

{
  # CUPS(Common Unix Printing System) 활성화하여 프린터 지원
  services.printing = {
    enable = true;
    drivers = [ pkgs.samsung-unified-linux-driver ];
  };

  # SANE(Scanner Access Now Easy) 활성화하여 스캐너 지원
  hardware.sane = {
    enable = true;
    extraBackends = [ 
      pkgs.samsung-unified-linux-driver 
      pkgs.sane-airscan
    ];
  };

  # 네트워크 프린터 및 스캐너 자동 검색을 위한 Avahi 및 mDNS 설정
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # 스캐너 및 프린터를 사용할 수 있도록 유저를 그룹에 추가
  users.users.${username}.extraGroups = [ "scanner" "lp" ];
}
