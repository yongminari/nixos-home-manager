# 🚀 NixOS + Home Manager (Unified Flake)

**yongminari**의 선언적(Declarative) 시스템 및 개인 환경 설정 저장소입니다.  
기존의 개별적인 NixOS 설정과 Home Manager 설정을 하나로 통합하여, **설치부터 앱 설정까지 한 번에** 복구할 수 있는 구조로 관리합니다.

## ✨ Features

- **🪟 Window Manager:** **Niri** (Scroll-based tiling compositor) - 현대적이고 매끄러운 사용자 경험.
- **⚡ Shell:** **Zsh** (Main), **Nushell (Experimental)**, **Bash** - **Starship** 테마 적용.
- **🛠️ Modern Core Utils:** `ls` → `eza`, `cat` → `bat`, `find` → `fd`, `grep` → `ripgrep`, `ps` → `procs`.
- **🚀 Advanced CLI Tools:** `gh` (GitHub), `lazydocker`, `xh` (HTTP), `sd` (sed replacement), `gping` (Visual Ping), `comma` (Run without install), `nix-tree`.
- **💻 Terminal:** **Ghostty** (Primary / High Performance), **Alacritty**.
- **📝 Editor:** **Neovim** (Lua-based modular config).
  - **Enhanced:** Neovim 0.11 support, ROS/Distrobox integration, `git-conflict-nvim`, and refined LSP visuals.
- **🚀 Desktop Shell:** **Noctalia Shell** (Integrated Bar, Launcher, & Notifications).
- **🔒 Security:** **OpenSSH Server** included.
- **🎨 Global Theme:** **Ayu Dark** (Local) / **Ayu Mirage** (Remote) - Unified aesthetics.

---

## 📂 Directory Structure

```text
nixos-home-manager/
├── flake.nix              # 통합 엔트리포인트 (System + User)
├── hosts/
│   └── <hostname>/        # [기기별 시스템 영역] (예: galaxy-book, desktop)
│       ├── configuration.nix           # 해당 기기의 OS 엔진 및 서비스 설정
│       └── hardware-configuration.nix  # 해당 기기의 하드웨어 종속 설정 (자동 생성)
├── home.nix               # [사용자 공통 영역] 메인 로더 & 패키지 관리
└── modules/               # 세부 모듈화된 설정들
    ├── shell/             # Zsh, Nushell, Bash, Starship 등
    ├── neovim/            # Neovim 전용 Lua 설정
    ├── niri/              # Niri 컴포지터 설정 (KDL)
    └── ...                # 기타 앱 및 테마 설정
```

---

## 🚀 Installation & Adding New Host

새로운 컴퓨터에 NixOS를 설치하거나, 기존 프로젝트에 새로운 기기를 추가하는 방법입니다.

### 1. 저장소 클론 (새 기기 기준)
```bash
git clone <YOUR_REPO_URL> ~/nixos-home-manager
cd ~/nixos-home-manager
```

### 2. 새로운 호스트 추가 절차
1.  **폴더 생성:** `hosts/` 폴더 아래에 원하는 호스트 이름으로 폴더를 만듭니다.
    ```bash
    mkdir -p hosts/<new-hostname>
    ```
2.  **하드웨어 설정 복사:** 해당 기기에서 생성된 파일을 복사해옵니다.
    ```bash
    cp /etc/nixos/hardware-configuration.nix ./hosts/<new-hostname>/
    ```
3.  **설정 파일 생성:** 기존 호스트의 `configuration.nix`를 복사한 뒤, `networking.hostName`을 새 이름으로 수정합니다.
4.  **Flake 등록:** `flake.nix`의 `nixosConfigurations` 섹션에 새 호스트 정의를 추가합니다.

### 3. 시스템 적용 (첫 빌드 시)
Flake를 사용하여 시스템 엔진과 모든 유저 설정을 한 번에 적용합니다.
```bash
# Git에 파일을 먼저 등록해야 Flake가 인식합니다.
git add .
sudo nixos-rebuild switch --flake .#<hostname>
```

---
## 🛠️ Management Guide

이 프로젝트는 더 나은 사용자 경험을 위해 **`nh` (Nix Helper)**를 사용합니다. 
> ⚠️ **주의:** `nh`는 이 설정을 통해 처음으로 시스템을 빌드한 이후부터 사용 가능합니다. 최초 설치 시에는 아래의 **표준 명령어**를 사용하세요.

### 1. 설정 변경 적용 (Switch)

| 대상 | nh 명령어 (권장) | 표준 명령어 (Native) |
| :--- | :--- | :--- |
| **전체 (시스템+유저)** | `nh os switch` | `sudo nixos-rebuild switch --flake .#<hostname>` |
| **유저 전용** | `nh home switch` | `home-manager switch --flake .` |

- `nh`는 빌드 시 `nix-output-monitor`를 통한 시각적 로그를 제공하며, 설정된 `flake` 경로를 자동으로 인식합니다.

### 2. 패키지 업데이트 및 청소

| 작업 | nh 명령어 | 표준 명령어 (Native) |
| :--- | :--- | :--- |
| **입력 소스 갱신** | - | `nix flake update` |
| **시스템 업데이트** | `nh os switch` | `sudo nixos-rebuild switch --flake .#<hostname>` |
| **오래된 세대 청소** | `nh clean all` | `nix-collect-garbage -d` |

상세한 `nh` 사용법은 [docs/nh.md](docs/nh.md)를 참고하세요.

---

## 🖥️ Desktop Quick Start

### ⌨️ Keybindings (Niri)
| Shortcut | Action |
| :--- | :--- |
| **`Super + Enter`** | Ghostty 터미널 실행 |
| **`Super + Space`** | Noctalia 앱 런처 실행 |
| **`Super + N`** | Noctalia 알림 센터 토글 |
| **`Super + Q`** | 현재 창 닫기 |
| **`Super + Shift + R`** | 설정 리로드 |
| **`Super + 1~9`** | 워크스페이스 이동 |
| **`Super + Shift + S`** | 화면 캡처 및 편집 (**Swappy**) |

### 🛠️ Git TUI (GitUI)
- **`Ctrl + h / l`**: 메인 탭 전환 (Home_env style)
- **`Shift + U`**: 스테이징 해제 (Reset item)
- **`?`**: 도움말 열기

### 🇰🇷 한글 입력 (Fcitx5)
1. `fcitx5-configtool` 실행.
2. `Input Method` 탭에서 **`Only Show Current Language` 해제**.
3. `+` 버튼을 눌러 **`Hangul`** 추가.
4. `Hangul` 설정에서 한글 키 등 전환 키 등록.

---

**Note:** 이 저장소는 `yongminari`의 개인 선호도에 최적화되어 있습니다. 재사용 시 `hosts/<hostname>/configuration.nix`의 호스트 이름 및 계정명을 확인하세요.
