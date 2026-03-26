# NixOS + Niri + Home Manager Configuration Guide

본 가이드는 `niri` 컴포지터와 `ghostty` 터미널, `fcitx5` 한글 입력기를 최적의 성능으로 구축하기 위한 **NixOS 전체 설정 지침서**입니다.

## 1. 시스템 영역 설정 (`/etc/nixos/configuration.nix`)

이 부분은 시스템의 "엔진"을 활성화하는 단계입니다. `root` 권한으로 수정 후 `sudo nixos-rebuild switch`를 실행하세요.

```nix
{ pkgs, ... }: {
  # 1. Niri 컴포지터 활성화
  programs.niri.enable = true;

  # 2. 한글 입력기(Fcitx5) 및 폰트 설정
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-hangul    # 한글 입력 엔진
      fcitx5-gtk       # GTK 앱 호환성 지원
    ];
  };

  # 3. 필수 패키지 및 폰트
  fonts.packages = with pkgs; [
    maple-mono-NF      # 영문 전용 (Nerd Font)
    d2coding           # 한글 전용 (Ligature)
  ];

  # 4. 폰트 우선순위 지정
  fonts.fontconfig.defaultFonts = {
    monospace = [ "Maple Mono NF" "D2Coding" ];
  };

  # 5. XDG 포털 (Wayland 환경 앱 연동 필수)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = "*";
  };
}
```

## 2. 홈 매니저 설정 (`home.nix`)

사용자 개인 환경의 "조종대"입니다. `home-manager switch --flake .#yongminari`를 실행하세요.

### **주요 패키지 목록**
- `ghostty`: 메인 터미널 (성능 매우 우수)
- `niri`: niri-msg 명령 사용을 위해 추가
- `fcitx5-hangul`: 한글 입력 엔진
- `qt6Packages.fcitx5-configtool`: 한글 입력기 설정 도구

### **Niri 핵심 설정 (config.kdl)**
- **Caps Lock**: Ctrl로 변경 (`options "ctrl:nocaps"`)
- **터치패드**: Natural Scrolling 및 Tap-to-click 활성화
- **단축키**: `Super+Return`으로 Ghostty 실행
- **한글 입력기**: 시작 시 `spawn-at-startup "fcitx5" "-d"` 실행

## 3. 한글 입력 마무리 (최초 1회 실행)

1. 터미널에서 `fcitx5-configtool` 실행.
2. `Input Method` 탭에서 **`Only Show Current Language` 해제**.
3. `+` 버튼을 눌러 **`Hangul`** 추가.
4. `Hangul` 설정에서 전환 키(예: 한글 키) 등록.

---

## 4. 팁 및 유지보수
- **설정 리로드**: `Super` + `Shift` + `R` (우리가 추가한 리로드 단축키)
- **단축키 확인**: `Super` + `Shift` + `?` (기본 도움말 창)
- **롤백**: 빌드가 잘못되었을 경우 부팅 시 이전 세대를 선택하여 즉시 복구 가능.

---
*Last Updated: 2026-03-26 by yongminari*
