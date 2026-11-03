{ ... }:

{
  local.desktop = {
    scale = "1.0";
    isLaptop = false;
    outputs = {
      left = "DP-2";
      right = "DP-3";
    };
    # 모니터 좌우 배치 변경: DP-2(왼쪽), DP-3(오른쪽)
    # 깜빡임 이슈 해결을 위해 주사율을 120Hz로 하향 조정
    extraConfig = ''
      output "DP-2" {
          mode "2560x1440@120"
          position x=0 y=0
      }
      output "DP-3" {
          mode "2560x1440@120"
          position x=2560 y=0
      }
    '';
  };
}
