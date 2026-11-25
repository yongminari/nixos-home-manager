# TODO

## Niri 효과의 별도 오픈소스 프로젝트 분리

상태: 후속 작업으로 보류. 현재 동작을 유지하며 다음 진행 시 아래 순서로 작업합니다.
프로젝트 이름은 가칭 `niri-effects`입니다.

- [ ] 창 열기·닫기·리사이즈 셰이더와 모니터·워크스페이스 효과의 분리 범위를 확정합니다.
- [ ] 외부 코드·셰이더의 출처와 라이선스를 확인하고 보존합니다.
- [ ] 구현 소스, 셰이더, 관련 테스트, 패키징을 별도 저장소로 옮깁니다.
- [ ] `monitor-flash.py`와 `workspace-warp.py`가 공유하는 렌더링 코드를 공통 모듈로 정리합니다.
- [ ] Noctalia 배경화면 연동을 선택 기능으로 분리합니다.
- [ ] 창 닫기의 축소·플로팅 전환·중앙 이동 동작을 옵션으로 분리합니다.
- [ ] 외부 프로젝트에 Nix 패키지와 Home Manager 모듈, 설치 예시, CI를 제공합니다.
- [ ] 이 저장소에는 Flake 입력, 모듈 연결, 호스트별 효과 선택·설정, 개인 단축키만 남깁니다.
- [ ] 기존 동작을 비교하고 Home Manager 빌드·적용 및 실제 화면에서 검증합니다.

### README 데모

- [ ] 실제 효과를 녹화합니다: 창 열기·닫기, 리사이즈, 모니터 전환, 워크스페이스 전환.
- [ ] 대표 효과를 짧은 반복 GIF로 만들어 외부 프로젝트 README에 넣습니다.
- [ ] 부드러운 움직임과 색감을 확인할 수 있는 MP4 원본 또는 데모 링크도 제공합니다.
- [ ] 효과 이름, 실행 방법, 필요한 환경을 데모 옆에 설명합니다.

### 후속 분리 후보

- [ ] Niri 창·모니터 도구: 워크스페이스 이동, 유휴 주사율 변경·복원.
- [ ] Ghostty·Kitty 터미널 셰이더: 원본 출처와 수정 범위를 정리한 뒤 분리 여부 결정.
- [ ] Noctalia 배경화면 동기화: 독립 도구 또는 연동 도구 모음에 포함할지 결정.

## 모듈별 미사용 코드 점검

각 체크박스는 해당 파일과 그 파일에서 연결하는 스크립트·설정의 점검 완료를 뜻합니다. 삭제 여부는 별도로 결정합니다. 52개 파일 점검을 완료했습니다. 회차별 근거는 [HANDOFF](../HANDOFF.md#모듈별-미사용-코드-점검)에서 확인합니다.

- 각 회차에는 한 파일에서 후보를 찾고 저장소 전체에서 호출 경로를 확인합니다. 단축키, systemd, 수동 CLI, 동적으로 읽는 파일과 테스트도 포함합니다.
- 호스트 조건이 있으면 세 호스트의 최종 설정을 비교합니다. 현재 비활성인 선택 기능과 플러그인 분리용 셰이더는 보존합니다.
- 점검 후 아래 항목을 체크하고 HANDOFF에 대상, 후보와 근거, 검증 결과, 다음 파일을 기록합니다. 실제 코드를 변경한 회차에는 관련 체크와 빌드 결과도 남깁니다.

### Niri

- [x] [modules/desktop/niri/default.nix](../modules/desktop/niri/default.nix)
- [x] [modules/desktop/niri/adaptive-close.nix](../modules/desktop/niri/adaptive-close.nix)
- [x] `modules/desktop/niri/genie-close-template.nix` 점검 후 제거
- [x] [modules/desktop/niri/monitor-flash.nix](../modules/desktop/niri/monitor-flash.nix)
- [x] [modules/desktop/niri/workspace-warp.nix](../modules/desktop/niri/workspace-warp.nix)

### 서비스

- [x] [modules/services/noctalia.nix](../modules/services/noctalia.nix)
- [x] `modules/services/codex-telegram-secrets.nix` 점검 후 제거
- [x] `modules/services/codex-telegram.nix` 점검 후 제거
- [x] [modules/services/tailscale.nix](../modules/services/tailscale.nix)
- [x] [modules/services/wireguard-client.nix](../modules/services/wireguard-client.nix)

### 셸

- [x] [modules/core/shell/bash.nix](../modules/core/shell/bash.nix)
- [x] [modules/core/shell/nushell.nix](../modules/core/shell/nushell.nix)
- [x] [modules/core/shell/utils.nix](../modules/core/shell/utils.nix)
- [x] [modules/core/shell/welcome.nix](../modules/core/shell/welcome.nix)
- [x] [modules/core/shell/yazi.nix](../modules/core/shell/yazi.nix)
- [x] [modules/core/shell/zellij.nix](../modules/core/shell/zellij.nix)
- [x] [modules/core/shell/zsh.nix](../modules/core/shell/zsh.nix)

### 개발 도구

- [x] [modules/dev/codex.nix](../modules/dev/codex.nix)
- [x] [modules/dev/containers.nix](../modules/dev/containers.nix)
- [x] [modules/dev/dev-tools.nix](../modules/dev/dev-tools.nix)
- [x] [modules/dev/git.nix](../modules/dev/git.nix)
- [x] [modules/dev/neovim.nix](../modules/dev/neovim.nix)

### 데스크톱

- [x] [modules/desktop/ghostty.nix](../modules/desktop/ghostty.nix)
- [x] [modules/desktop/gui-apps.nix](../modules/desktop/gui-apps.nix)
- [x] [modules/desktop/host-options.nix](../modules/desktop/host-options.nix)
- [x] [modules/desktop/hypridle.nix](../modules/desktop/hypridle.nix)
- [x] [modules/desktop/idle-blur.nix](../modules/desktop/idle-blur.nix)
- [x] [modules/desktop/kitty.nix](../modules/desktop/kitty.nix)
- [x] [modules/desktop/nixos-desktop.nix](../modules/desktop/nixos-desktop.nix)
- [x] [modules/desktop/swappy.nix](../modules/desktop/swappy.nix)

### 시스템 공통

- [x] [modules/core/company-ca.nix](../modules/core/company-ca.nix)
- [x] [modules/core/containers.nix](../modules/core/containers.nix)
- [x] [modules/core/dbus.nix](../modules/core/dbus.nix)
- [x] [modules/core/fonts.nix](../modules/core/fonts.nix)
- [x] [modules/core/nixos-base.nix](../modules/core/nixos-base.nix)
- [x] [modules/core/sops.nix](../modules/core/sops.nix)
- [x] [modules/core/system-utils.nix](../modules/core/system-utils.nix)
- [x] [modules/core/theme.nix](../modules/core/theme.nix)

### 하드웨어

- [x] [modules/hardware/printing.nix](../modules/hardware/printing.nix)
- [x] [modules/hardware/samsung-galaxy-book.nix](../modules/hardware/samsung-galaxy-book.nix)

### 호스트별 설정

- [x] [hosts/ai-x1-pro/configuration.nix](../hosts/ai-x1-pro/configuration.nix)
- [x] [hosts/ai-x1-pro/hardware-configuration.nix](../hosts/ai-x1-pro/hardware-configuration.nix)
- [x] [hosts/ai-x1-pro/home.nix](../hosts/ai-x1-pro/home.nix)
- [x] [hosts/galaxy-book/configuration.nix](../hosts/galaxy-book/configuration.nix)
- [x] [hosts/galaxy-book/hardware-configuration.nix](../hosts/galaxy-book/hardware-configuration.nix)
- [x] [hosts/galaxy-book/home.nix](../hosts/galaxy-book/home.nix)
- [x] [hosts/nxtp-office-desktop/configuration.nix](../hosts/nxtp-office-desktop/configuration.nix)
- [x] [hosts/nxtp-office-desktop/hardware-configuration.nix](../hosts/nxtp-office-desktop/hardware-configuration.nix)
- [x] [hosts/nxtp-office-desktop/home.nix](../hosts/nxtp-office-desktop/home.nix)

### 진입점과 검증

- [x] [checks/default.nix](../checks/default.nix)
- [x] [flake.nix](../flake.nix)
- [x] [home.nix](../home.nix)
