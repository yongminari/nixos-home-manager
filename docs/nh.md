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
