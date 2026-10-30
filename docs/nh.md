# 🚀 nh (Nix Helper) Usage Guide

`nh`는 `nixos-rebuild`와 `home-manager` 명령어를 더 직관적이고 시각적으로 사용하기 위한 도구입니다.

## 🛠️ Key Commands

### 1. 시스템 및 유저 설정 적용 (Switch)
기존의 `sudo nixos-rebuild switch`와 `home-manager switch`를 대체합니다.

```bash
# 어느 경로에서든 현재 호스트의 시스템 + 유저 설정 적용
ns

# 어느 경로에서든 현재 호스트의 Home Manager 설정만 적용
hms

# 저장소 안에서 nh를 직접 실행하는 경우
nh os switch .
nh home switch .
```

`ns`와 `hms`는 `${HOME}/nixos-home-manager`를 Flake 경로로 전달합니다. `nh home switch`는 현재 hostname을 기준으로 `yongminari@<hostname>` 출력을 선택하므로 Niri 모니터 설정과 GPU별 환경 변수도 해당 NixOS 호스트 구성과 일치합니다.

- **장점**: 
    - 빌드 과정을 `nix-output-monitor`를 통해 그래프로 보여줍니다.
    - `hms`와 `ns`가 홈 디렉터리 아래의 저장소 경로를 직접 전달하므로 어느 디렉터리에서든 실행 가능합니다.

### 2. 패키지 검색 (Search)
`nix search`보다 훨씬 빠르고 깔끔한 결과를 보여줍니다.

```bash
nh search <package-name>
```

### 3. 시스템 청소 (Clean)
오래된 빌드 세대(Generations)를 삭제하여 디스크 용량을 확보합니다.

```bash
# 4일 이상 지났거나 최신 3개 이외의 세대 삭제
nh clean all
```
*설정에 따라 자동으로 실행되도록 구성되어 있습니다.*

---

## 💡 Troubleshooting

### "No installable specified" 에러 발생 시

경로 없이 `nh os switch` 또는 `nh home switch`를 실행하면 `/etc/nixos`나 Home Manager 기본 경로에서 Flake를 찾다가 실패할 수 있습니다. `ns`/`hms`를 사용하거나 저장소 경로를 직접 전달하세요.

```bash
nh os switch ~/nixos-home-manager
nh home switch ~/nixos-home-manager
```

현재 기기의 `hostname`은 `flake.nix`에 정의된 `galaxy-book`, `ai-x1-pro`, `nxtp-office-desktop` 중 하나여야 합니다. 다른 호스트의 시스템 설정은 해당 호스트에서 전환하고, 현재 호스트에서는 평가만 수행하세요.

```bash
nh os build ~/nixos-home-manager#ai-x1-pro
```

## 적용 경로와 롤백 범위

- `ns`: 현재 호스트의 시스템과 통합 Home Manager를 함께 적용합니다. GPU, 방화벽, 시스템 서비스, SOPS 비밀값, OS 환경 변수 변경은 이 경로를 사용합니다.
- `hms`: 현재 호스트의 독립 Home Manager만 적용합니다. 사용자 설정만 바꿀 때 사용합니다. `osConfig`는 저장소의 선언을 읽으며, 그 OS 설정이 이미 실행 중이라는 보장은 없습니다.
- 두 경로는 같은 공통·호스트별 Home Manager 모듈을 사용하지만 프로필과 세대는 별도로 관리됩니다. 통합 경로는 `useUserPackages = true`로 시스템 사용자 패키지를 설치합니다.
- 통합 경로의 기존 파일 백업 확장자는 `backup`입니다. 독립 경로에서 충돌 파일을 백업하려면 `nh home switch . -b backup`을 사용하고, 같은 이름의 이전 백업이 있는지 확인합니다.
- 시스템 롤백은 이후 독립 `hms`로 적용한 파일과 사용자 데이터를 함께 되돌리는 기능이 아닙니다. 복구할 저장소 리비전을 선택한 뒤 필요한 적용 경로를 다시 실행합니다.
- `stateVersion`은 패키지 버전 번호가 아닙니다. 업데이트나 리팩토링을 이유로 올리지 않습니다.

## 변경 검증

```bash
git add .
git diff --cached --check
nix flake check --no-update-lock-file
nh home build .
nh os build .
```

검사가 끝나면 변경 범위에 맞게 `hms` 또는 `ns`로 적용합니다. Niri 설정은 자동으로 다시 읽으며, 입력기·세션 환경 변경은 로그아웃/로그인이 필요할 수 있습니다. 다른 호스트의 실제 적용은 해당 호스트에서 실행합니다.

노트북의 `touchpad-control.kdl`은 최초 Home Manager 활성화 시 쓰기 가능한 파일로 생성합니다. 이후 활성화는 기존 켜짐/꺼짐 상태를 보존합니다.
