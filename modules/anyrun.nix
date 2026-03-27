{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    anyrun
  ];

  # anyrun 설정 (검증된 플러그인 경로 사용)
  xdg.configFile."anyrun/config.ron".text = ''
    Config(
      x: Fraction(0.5),
      y: Fraction(0.3),
      width: Fraction(0.3),
      height: Absolute(0),
      hide_icons: false,
      ignore_exclusive_zones: false,
      layer: Overlay,
      hide_plugin_info: true,
      close_on_click: true,
      show_results_immediately: false,
      max_entries: None,
      plugins: [
        "${pkgs.anyrun}/lib/libapplications.so",
        "${pkgs.anyrun}/lib/libshell.so",
        "${pkgs.anyrun}/lib/libnix_run.so",
        "${pkgs.anyrun}/lib/libwebsearch.so",
      ],
    )
  '';
}
