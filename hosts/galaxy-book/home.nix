{ ... }:

{
  # 컨트롤센터·런처 등 바 이외 Noctalia UI의 호스트별 배율입니다.
  programs.noctalia.settings.accessibility.ui_scale = 1.15;

  local.desktop = {
    scale = "1.0";
    isLaptop = true;
    outputs = null;
    extraConfig = "";
  };
}
