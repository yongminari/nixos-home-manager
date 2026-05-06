{ config, pkgs, inputs, ... }:

let
  # Flake input에서 공식 테마 소스를 가져옵니다.
  hyprlock-themes = inputs.hyprlock-themes;
in
{
  # 공식 테마 파일들을 ~/.config/hypr/themes 에 심볼릭 링크로 연결합니다.
  home.file.".config/hypr/hyprlock-mocha.conf".source = "${hyprlock-themes}/mocha.conf";

  # 메인 hyprlock.conf 에서는 공식 테마를 불러오고 필요한 부분(폰트 등)만 수정합니다.
  xdg.configFile."hypr/hyprlock.conf".text = ''
    # 1. Catppuccin Mocha 공식 테마 임포트
    source = ~/.config/hypr/hyprlock-mocha.conf

    # 2. 사용자 맞춤 설정 (기존 테마 설정 덮어쓰기)
    background {
        monitor =
        path = screenshot
        blur_passes = 2
    }

    # 시계 폰트 수정 (Maple Mono로 일관성 유지)
    label {
        monitor =
        text = $TIME
        color = $mauve
        font_size = 90
        font_family = Maple Mono NF Bold
        position = 0, 80
        halign = center
        valign = center
    }

    # 입력창 디자인 살짝 보강
    input-field {
        monitor =
        size = 250, 60
        outline_thickness = 2
        dots_size = 0.2
        dots_spacing = 0.2
        dots_center = true
        outer_color = $mauve
        inner_color = $surface0
        font_color = $text
        fade_on_empty = false
        placeholder_text = <i>Input Password...</i>
        hide_input = false
        position = 0, -120
        halign = center
        valign = center
    }
  '';
}
