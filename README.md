# 🚀 NixOS + Home Manager (Unified Flake)

**yongminari**의 선언적(Declarative) 시스템 및 개인 환경 설정 저장소입니다.  
기존의 개별적인 NixOS 설정과 Home Manager 설정을 하나로 통합하여, **설치부터 앱 설정까지 한 번에** 복구할 수 있는 구조로 관리합니다.

## ✨ Features

- **🪟 Window Manager:** **Niri** (Scroll-based tiling compositor) - 현대적이고 매끄러운 사용자 경험.
- **⚡ Shell:** **Zsh** (Main), **Nushell (Experimental)**, **Bash** - **Starship** 테마 적용.
- **🛠️ Modern Core Utils:** `ls` → `eza`, `cat` → `bat`, `find` → `fd`, `grep` → `ripgrep`.
- **💻 Terminal:** **Ghostty** (성능 최적화), **Alacritty**.
- **📝 Editor:** **Neovim** (Lua 기반 모듈형 설정).
- **🚀 App Launcher:** **Anyrun** (Wayland-native).
- **📊 Status Bar:** **Waybar** (Catppuccin Mocha 테마).
- **🔔 Notification:** **SwayNC** (Notification Center).
- **🔒 Security:** **OpenSSH Server** 기본 탑재 (원격 관리 가능).
- **🎨 Global Theme:** **Catppuccin Mocha** 기반의 통일된 미학.

---

## 📂 Directory Structure

```text
nixos-home-manager/
├── flake.nix              # 통합 엔트리포인트 (System + User)
├── hosts/
│   └── nixos/             # [시스템 영역]
│       ├── configuration.nix           # OS 엔진 및 서비스 설정
│       └── hardware-configuration.nix  # 하드웨어 종속 설정 (Git 무시)
├── home.nix               # [사용자 영역] 메인 로더 & 패키지 관리
└── modules/               # 세부 모듈화된 설정들
    ├── shell/             # Zsh, Nushell, Bash, Starship 등
    ├── neovim/            # Neovim 전용 Lua 설정
    ├── niri/              # Niri 컴포지터 설정 (KDL)
    └── ...                # 기타 앱 및 테마 설정
```

---

## 🚀 Installation (New OS Install)

새로운 컴퓨터에 NixOS를 설치하고 이 환경을 그대로 복구하는 방법입니다.

### 1. 기본 NixOS 설치 및 클론
NixOS 설치 직후 생성된 하드웨어 정보를 보존하면서 저장소를 클론합니다.
```bash
# 저장소 클론
git clone <YOUR_REPO_URL> ~/nixos-home-manager
cd ~/nixos-home-manager
```

### 2. 하드웨어 설정 복사 (핵심)
설치 시 생성된 하드웨어 구성 파일을 프로젝트 폴더로 가져옵니다. (이 파일은 `.gitignore`에 의해 보호됩니다.)
```bash
cp /etc/nixos/hardware-configuration.nix ./hosts/nixos/
```

### 3. 마법의 명령어 실행 (전체 복구)
Flake를 사용하여 시스템 엔진과 모든 유저 설정을 한 번에 적용합니다.
```bash
sudo nixos-rebuild switch --flake .#nixos
```

---

## 🛠️ Management Guide

| 상황 | 실행 명령어 | 설명 |
| :--- | :--- | :--- |
| **전체 업데이트 (권장)** | `sudo nixos-rebuild switch --flake .#nixos` | **시스템 + 유저** 설정을 한꺼번에 동기화 |
| **유저 설정만 업데이트** | `home-manager switch --flake .#yongminari` | 계정 관련 설정만 빠르게 적용할 때 |
| **NixOS 채널 업데이트** | `nix flake update` | `flake.lock`의 라이브러리 버전을 최신으로 갱신 |

---

## 🖥️ Desktop Quick Start

### ⌨️ Keybindings (Niri)
| Shortcut | Action |
| :--- | :--- |
| **`Super + Enter`** | Ghostty 터미널 실행 |
| **`Super + D`** | Anyrun 앱 런처 실행 |
| **`Super + Q`** | 현재 창 닫기 |
| **`Super + Shift + R`** | 설정 리로드 |
| **`Super + 1~9`** | 워크스페이스 이동 |
| **`Super + Shift + S`** | 화면 캡처 및 편집 (**Swappy**) |

### 🇰🇷 한글 입력 (Fcitx5)
1. `fcitx5-configtool` 실행.
2. `Input Method` 탭에서 **`Only Show Current Language` 해제**.
3. `+` 버튼을 눌러 **`Hangul`** 추가.
4. `Hangul` 설정에서 한글 키 등 전환 키 등록.

---

**Note:** 이 저장소는 `yongminari`의 개인 선호도에 최적화되어 있습니다. 재사용 시 `hosts/nixos/configuration.nix`의 호스트 이름 및 계정명을 확인하세요.
