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

  # ai-x1-pro와 galaxy-book에서만 사용하는 프린터입니다.
  # 공유기에서 20:0B:74:CF:BB:D5에 192.168.45.173을 DHCP 예약했습니다.
  # 부팅 시 영구 IPP 큐가 없거나 주소가 다른 경우에만 등록합니다.
  # 기존 큐의 옵션과 사용자가 선택한 기본 프린터는 유지합니다.
  systemd.services.canon-mf667cx-printer = {
    description = "Configure Canon MF667Cx IPP Everywhere printer";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" "cups.service" ];
    wants = [ "network-online.target" "cups.service" ];
    path = [ pkgs.cups ];
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "30s";
    };
    script = ''
      export LC_ALL=C
      printer_name=Canon_MF660C_Series
      printer_uri=ipp://192.168.45.173:631/ipp/print
      current_device="$(lpstat -v "$printer_name" 2>/dev/null || true)"

      if [ -z "$current_device" ]; then
        # 최초 등록에는 프린터 연결이 필요합니다. 오프라인이었다면 연결 후
        # sudo systemctl start canon-mf667cx-printer 로 다시 등록할 수 있습니다.
        lpadmin -p "$printer_name" \
          -D "Canon imageCLASS MF667Cx" \
          -E -v "$printer_uri" -m everywhere -o media=iso_a4_210x297mm
      elif [ "$current_device" != "device for $printer_name: $printer_uri" ]; then
        lpadmin -p "$printer_name" -v "$printer_uri"
      fi

      if [ "$(lpstat -d)" = "no system default destination" ]; then
        lpadmin -d "$printer_name"
      fi
    '';
  };

  # 스캐너 및 프린터를 사용할 수 있도록 유저를 그룹에 추가
  users.users.${username}.extraGroups = [ "scanner" "lp" ];
}
