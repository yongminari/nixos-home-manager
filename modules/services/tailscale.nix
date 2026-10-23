{ ... }:

{
  services.tailscale = {
    enable = true;
    # 기기 간 직접 연결에 사용하는 UDP 포트를 허용합니다.
    openFirewall = true;
  };

  # 최초 적용 후 각 기기에서 `sudo tailscale up`으로 같은 개인 계정에 로그인합니다.
  # 인증 상태는 /var/lib/tailscale에 보관되며 재부팅 후에도 유지됩니다.
  # SSH는 기존 OpenSSH를 사용하며, 서브넷 라우터와 exit node는 설정하지 않습니다.
}
