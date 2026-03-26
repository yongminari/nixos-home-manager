# Niri & Utils System Setup Guide

본 가이드는 `niri`, `ghostty`, `anyrun`, `waybar`를 성공적으로 구동하기 위한 **NixOS 시스템 설정(System Area)** 안내입니다.

## 1. `/etc/nixos/configuration.nix` 수정

`root` 권한으로 `/etc/nixos/configuration.nix` 파일을 열고 다음 설정을 추가하거나 수정해 주세요.

```nix
{ pkgs, ... }: {
  # Niri 컴포지터 활성화 (세션 관리자 등록 및 기본 환경 구성)
  programs.niri.enable = true;

  # Ghostty 등 최신 터미널을 위한 폰트 설정 (Maple Mono NF 및 D2Coding)
  fonts.packages = with pkgs; [
    maple-mono-NF  # 영어 (Maple Mono Nerd Font)
    d2coding       # 한국어 (D2Coding Ligature 포함)
  ];

  # (선택 사항) 시스템 기본 폰트 순서 지정 (영문은 Maple, 한글은 D2Coding이 우선되도록)
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "Maple Mono NF" "D2Coding" ];
      sansSerif = [ "Maple Mono NF" "D2Coding" ];
      serif = [ "Maple Mono NF" "D2Coding" ];
    };
  };

  # 웨일랜드 화면 공유 및 포털 기능 (Anyrun 및 기타 앱 연동)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = "*";
  };

  # (선택 사항) 로그인 화면 설정 (GDM 또는 SDDM)
  # services.xserver.displayManager.gdm.enable = true;
  # services.displayManager.defaultSession = "niri";
}
```

## 2. 설정 적용 방법

1.  시스템 설정을 먼저 적용합니다:
    ```bash
    sudo nixos-rebuild switch
    ```
2.  현재 Home Manager 설정을 적용합니다 (이 레포지토리 폴더에서 실행):
    ```bash
    nix run .#homeConfigurations.yongminari.activationPackage
    ```
    또는 일반적인 home-manager 명령어를 사용하세요:
    ```bash
    home-manager switch --flake .
    ```

## 3. 실행 및 확인

*   재부팅 또는 로그아웃 후, 로그인 화면에서 **niri** 세션을 선택하여 로그인하세요.
*   `Mod4 (Super/Win)` + `Enter`: Ghostty 실행
*   `Mod4` + `D`: Anyrun 실행
*   상단에 `Waybar`가 자동으로 표시됩니다.

---

**참고**: `anyrun`은 첫 실행 시 플러그인 경로 설정이 필요할 수 있습니다. `home.nix`에 추가된 설정을 확인해 보세요.
