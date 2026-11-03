{ pkgs, ... }:

{
  # ai-x1-pro의 RTX 2070 SUPER LED 제어용. 실제 소등은 카드 지원 여부에 따릅니다.
  environment.systemPackages = [ pkgs.openrgb ];
  services.udev.packages = [ pkgs.openrgb ];
  boot.kernelModules = [ "i2c-dev" ];

  systemd.services.nvidia-egpu-led-off = {
    description = "Turn off RTX 2070 SUPER LEDs";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" "systemd-udev-trigger.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "nvidia-egpu-led";
      TimeoutStartSec = "60s";
      # 장치 번호 대신 GPU 이름을 선택하여 다른 RGB 장치에는 적용하지 않습니다.
      ExecStart = "${pkgs.openrgb}/bin/openrgb --noautoconnect --config /var/lib/nvidia-egpu-led --device 'RTX 2070' --color 000000";
    };
  };
}
