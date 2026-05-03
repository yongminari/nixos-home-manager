{ config, pkgs, ... }:

{
  # rclone mount을 위한 systemd 사용자 서비스 설정
  systemd.user.services = {
    rclone-mount-gdrive = {
      Unit = {
        Description = "rclone-mount-gdrive";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "simple";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/mnt/gdrive";
        ExecStart = "${pkgs.rclone}/bin/rclone mount gdrive: %h/mnt/gdrive --vfs-cache-mode full --vfs-cache-max-age 24h --buffer-size 128M --vfs-read-chunk-size 64M --vfs-read-chunk-size-limit 1G";
        ExecStop = "/usr/bin/fusermount3 -u %h/mnt/gdrive";
        Restart = "on-failure";
        RestartSec = "10s";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    rclone-mount-onedrive = {
      Unit = {
        Description = "rclone-mount-onedrive";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "simple";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/mnt/onedrive";
        ExecStart = "${pkgs.rclone}/bin/rclone mount onedrive: %h/mnt/onedrive --vfs-cache-mode full --vfs-cache-max-age 24h --buffer-size 128M --vfs-read-chunk-size 64M --vfs-read-chunk-size-limit 1G";
        ExecStop = "/usr/bin/fusermount3 -u %h/mnt/onedrive";
        Restart = "on-failure";
        RestartSec = "10s";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
