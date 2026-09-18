{ config, pkgs, username, ... }:

{
  # CUPS(Common Unix Printing System) 활성화하여 프린터 지원
  services.printing = {
    enable = true;
    drivers = [ pkgs.samsung-unified-linux-driver ];

    # IPP Everywhere/AirPrint 프린터를 자동 검색하여 드라이버리스 큐 생성
    browsed.enable = true;
    browsedConf = ''
      CreateIPPPrinterQueues driverless
    '';
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

  # DHCP 주소를 Avahi로 조회하여 Chrome에서도 보이는 영구 IPP 큐를 갱신
  systemd.services.canon-mf667cx-printer = {
    description = "Configure Canon MF667Cx IPP Everywhere printer";
    after = [ "network-online.target" "avahi-daemon.service" "cups.service" ];
    wants = [ "network-online.target" "avahi-daemon.service" "cups.service" ];
    path = [ pkgs.avahi pkgs.coreutils pkgs.cups ];
    serviceConfig.Type = "oneshot";
    script = ''
      printer_address="$(avahi-resolve-host-name -4 Canon246c0c.local | cut -f2)"
      test -n "$printer_address"

      lpadmin \
        -p Canon_MF660C_Series \
        -D "Canon imageCLASS MF667Cx" \
        -E \
        -v "ipp://$printer_address:631/ipp/print" \
        -m everywhere \
        -o media=iso_a4_210x297mm
      lpadmin -d Canon_MF660C_Series
    '';
  };

  systemd.timers.canon-mf667cx-printer = {
    description = "Refresh Canon MF667Cx DHCP address";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnActiveSec = "5s";
      OnUnitActiveSec = "5min";
      Persistent = true;
    };
  };

  # 스캐너 및 프린터를 사용할 수 있도록 유저를 그룹에 추가
  users.users.${username}.extraGroups = [ "scanner" "lp" ];
}
