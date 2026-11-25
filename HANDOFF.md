# System Review Handoff

최종 갱신: 2026-11-25. 완료 항목은 제목만 유지하고, 상세 이력은 Git에서 확인합니다.

## 모듈별 미사용 코드 점검

전체 목록과 진행 상태는 [TODO](docs/TODO.md#모듈별-미사용-코드-점검)에 기록합니다.

**다음 회차**는 [utils.nix](modules/core/shell/utils.nix)입니다. 공통 별칭과 SSH·프롬프트·완성 도구의 셸별 연동을 점검합니다.

### 2026-11-25 · Nushell

- 세 호스트의 통합·독립 Home Manager 구성에서 같은 `config.nu`를 생성하며 현재 PC의 설치본과 일치합니다. `env.nu`는 Home Manager 세션 변수를 불러오는 첫 줄을 제외한 내용이 같습니다.
- Nushell 전용 `ll`·`lt`·`cat`·`g`·`v` 선언을 제거하고 [공통 별칭](modules/core/shell/utils.nix#L4)을 사용합니다. 세 호스트의 통합·독립 Home Manager 설정에서 별칭을 검증했습니다. nxtp-office-desktop에서 홈 빌드 및 적용 후 Bash·Zsh·Nushell로 다섯 명령의 실제 출력을 비교했고, Bash·Zsh의 `ls`는 eza, Nushell의 `ls`는 내장 테이블임을 확인했습니다. 수동 Carapace 완성 함수는 fzf가 이전 완성 함수로 보관해 호출합니다.
- Nushell 0.116.1에서 `ssh -p 2222 host`가 연결 전에 실패하던 문제를 수정했습니다. 공통 `ssh`를 `def --wrapped`로 선언해 SSH 옵션을 전달합니다. 생성된 설정에서 포트·키 파일·점프 호스트 옵션, Ghostty·Kitty·멀티플렉서·원격 SSH 분기, `zellij-ssh`와 인자 없는 호출을 포함한 모의 시험 7건이 통과했습니다. nxtp-office-desktop에서 홈 빌드와 `hms` 적용을 마쳤습니다.

### 2026-11-25 · Bash

- 세 호스트의 통합·독립 Home Manager 설정은 같은 `.bashrc`를 생성하며, 현재 기기에 설치된 파일도 일치합니다. 생성된 파일은 맨 앞에서 비대화형 셸을 반환시키므로 [환영 메시지](modules/core/shell/bash.nix#L11) 앞의 `[[ $- == *i* ]]`는 중복 조건입니다.
- 설치된 `.bashrc`를 별도 Bash에서 읽고 모의 명령으로 확인했습니다. 대화형에서는 공통 SSH·Zellij 함수가 정의되고 환영 명령이 한 번 호출됩니다. `fnm`이 PATH에 있으면 Bash용 초기화를 실행하고, 없으면 건너뜁니다. 비대화형에서는 모두 건너뜁니다. 세 호스트 모두 `welcome-msg`를 설치하며 `fnm`은 시스템·홈 패키지에 직접 선언하지 않아 선택 분기로 보존합니다.
- 후속 정리에서 Bash·Zsh 공유 스크립트의 `try_alias`와 네 호출을 제거했습니다. Bash의 `lt`도 기존 Zsh·Nushell처럼 `--long`이 포함된 상세 트리를 표시합니다.

### 2026-11-25 · WireGuard 클라이언트

- galaxy-book·ai-x1-pro의 최종 NixOS 설정에 수동 시작용 `wg-quick-wg0.service`가 생성됩니다. 부팅 시 시작 대상은 비어 있고, wg-quick은 두 sops 키 파일과 인터페이스·피어 설정을 사용합니다. 모듈에서 삭제할 항목은 없습니다.
- 세 호스트의 통합·독립 Home Manager 설정에서 Zsh 별칭을 확인했습니다. nxtp-office-desktop에도 별칭은 있으나 대상 유닛과 WireGuard 비밀 선언은 없고, 실제 장치에서도 유닛이 없음을 확인했습니다. [운영 문서](docs/secrets-guide.md#-wireguard-vpn-제어)에 실제 systemctl 명령과 사용 호스트를 반영했습니다. VPN 연결 상태는 변경하지 않았습니다.

### 2026-11-25 · Tailscale

- 세 호스트 모두 `enable = true`로 CLI를 설치하고 부팅 시 `tailscaled.service`를 시작합니다. `openFirewall = true`는 세 호스트의 방화벽에 직접 연결용 UDP 41641을 허용합니다. 두 옵션 모두 사용하므로 삭제 후보가 없습니다.
- nxtp-office-desktop에서 서비스 실행, `tailscale status`의 로컬 노드 온라인 상태, UDP 41641 소켓을 확인했습니다. 다른 두 호스트는 저장소의 최종 설정을 평가했습니다.

### 2026-11-25 · Codex Telegram 완료 알림 제거

- 사용하지 않는 공통 알림 모듈, 비밀 선언, 전용 스크립트와 설정 가이드를 제거했습니다. 이전 구현과 보류한 양방향 연동 구상은 Git 커밋 `8e070e4`에서 확인할 수 있습니다.
- 세 호스트의 NixOS·Home Manager 최종 설정을 평가했습니다. nxtp-office-desktop은 시스템·홈 빌드와 `hms` 적용을 마쳤고, 실제 Codex 설정에서 Telegram 훅이 없고 터미널 알림이 켜져 있음을 확인했습니다. 후속 점검에서 `/run/current-system`이 제거 후 빌드한 시스템 경로와 일치함을 확인했습니다.

### 2026-11-25 · Noctalia

- 세 호스트의 최종 설정에서 Wallhaven 타이머(15분), 출력 재연결 동기화 서비스, 시계 마이그레이션 시작 훅을 확인했습니다. galaxy-book은 시각·날짜 위젯 한 쌍, 다른 두 호스트는 좌우 한 쌍씩입니다. 현재 기기는 마이그레이션 완료 표시가 있으며 구버전 상태를 위한 훅은 보존합니다. 배경화면 동기화 Nix 체크가 통과했습니다.
- 정리 후보는 [내장 배경화면 자동화 설정](modules/services/noctalia.nix#L275)의 `interval_seconds = 1800`과 `order = "random"`입니다. 고정된 Noctalia 소스의 `WallpaperAutomationConfig` 기본값과 같고, 실제 Wallhaven 타이머는 별도입니다. `recursive = true`는 기본값과 다르며 수동 배경화면 탐색 경로에서도 읽습니다. 이번에는 Noctalia 설정을 변경하지 않았습니다.

### 2026-11-25 · Niri 워크스페이스 전환 효과

- 배경화면 물결 서비스 경로에서만 포커스 추적기를 한 번 생성하도록 정리했습니다. 옵션이 꺼졌거나 수동 미리보기이면 생성·갱신을 생략합니다. 워크스페이스·활성 열 추적은 기존대로 동작합니다.
- 세 호스트에서 같은 서비스 패키지를 평가했고 nxtp-office-desktop에 시스템·홈 설정을 적용했습니다. 설치된 코드에 모의 이벤트를 입력해 물결 옵션별 추적기 생성 횟수(0/1), 워크스페이스·모니터 이동 효과 호출, 미리보기 초기화, 별도 모니터 서비스 경로를 검증했습니다.

### 2026-11-25 · Niri 모니터 전환 효과

- 세 호스트의 Home Manager 최종 설정에서 동일한 서비스 패키지, `effect = "screen-ripple"`, `windowOpen = false`, `windowClose = false`를 확인했습니다. 현재 기기에서는 해당 패키지의 사용자 서비스가 실행 중이며 CLI 도움말에 미리보기와 데모가 등록돼 있습니다.
- 창 물결 옵션이 모두 꺼진 경우 창 추적기의 생성과 이벤트별 갱신을 제거했습니다. 모니터 이동 감지와 선택 가능한 창 효과, 미리보기·데모는 유지합니다.
- 세 호스트가 같은 패키지를 선택하는지 평가했습니다. nxtp-office-desktop에 시스템·홈 설정을 적용하고 두 효과 서비스의 실행 상태를 확인했습니다. 설치된 코드에 창 열기·닫기·모니터 이동 이벤트를 입력해 옵션 네 조합의 효과 호출과 추적기 생성 여부를 검증했습니다.

### 2026-11-25 · Niri 창 닫기

- 지니 효과의 흡입점을 하단 중앙에 고정하기로 하여 미사용 방향 인자와 계산, 진단 옵션, 가변 KDL 템플릿과 닫을 때마다 설정을 다시 읽던 처리를 제거했습니다. 지니와 CRT 효과는 공통 Niri 설정에 선언합니다.
- [Mod+Q 도구](modules/desktop/niri/adaptive-close.py)는 타일 창을 플로팅으로 전환해 축소·중앙 정렬하고, 같은 작업공간에 남은 타일 창이 있으면 포커스를 넘긴 뒤 원래 ID를 닫습니다. 입력 간 대상 선택과 인계는 직렬화하고 닫기 애니메이션은 기다리지 않습니다.
- 회귀 테스트 8개와 세 호스트의 Niri 설정 체크를 통과했습니다. nxtp-office-desktop에서 시스템·홈 설정을 적용하고 실행 중인 Niri에 설정을 다시 불러왔습니다.

### 2026-11-25 · Niri 공통 설정

- [default.nix](modules/desktop/niri/default.nix)의 패키지와 생성 KDL을 [단축키](modules/desktop/niri/binds.kdl) 및 세 호스트의 최종 Home Manager 옵션과 대조했습니다. 플로팅 전환은 `Mod+W`, 출력 전환은 `Mod+Ctrl+H/L`에서 호출합니다. 삭제를 제안할 코드가 확인되지 않았습니다.
- 세 호스트 모두 `adaptiveGenieClose = true`, `windowAnimation = "genie"`입니다. 현재 선택되지 않은 닫기 효과와 연결 분기는 플러그인 분리를 위해 보존합니다. 유휴 blur 분기는 ai-x1-pro, 터치패드 초기화는 galaxy-book에서 사용합니다.
- 별도 관찰 사항으로, 공통 바인딩에는 터치패드 전환 키가 있지만 호출 대상 스크립트는 노트북에서만 생성합니다. 기능 자체는 galaxy-book에서 사용하므로 일괄 삭제 후보에서 제외했습니다.
- `checks.x86_64-linux.niri-{galaxy-book,ai-x1-pro,nxtp-office-desktop}` 세 항목의 빌드가 통과했습니다. 이 회차에서는 설정 변경이나 장치 적용 없이 평가와 구성 파일 검증을 수행했습니다.

## 남은 검증

| 항목 | 대상 | 다음 확인 |
|---|---|---|
| 유휴 blur 잠금 화면 | ai-x1-pro | 1분 무잠금 시험에서 blur·복귀 사용자 확인. 기본 잠금10분에서는 일반 레이어가 가려질 수 있음. 잠금 시간은 유지 |
| 로그아웃 PipeWire 충돌 | ai-x1-pro | 11/06 15:36:28 GNOME 전환 전 pipewire segfault 기록 발견. 기존 GDM 충돌과 같은지 미조사, 현재 서비스 정상 |
| 부팅 화면 깨짐 | ai-x1-pro | 사용자: 텍스트 부팅 중 줄무늬·색 점·글자 깨짐. 현재 부팅 simpledrm→NVIDIA fb 전환은 커널 시작 약8.5초, fb3840×2160→Niri5120×2160@120. 관련 Xid 없음. 사용자 확인: GUI 진입 후 깨짐 없음. DP 복귀 실패와 동일 원인인지 미확정 |
| D-Bus | ai-x1-pro | 중복 경고 제거·API 확인 완료. 파일 선택·화면 공유·키링 실제 사용 확인 |
| Canon 프린터 | ai-x1-pro, galaxy-book | 실제 인쇄 확인. AI 호스트는 재부팅 후 큐·기본 프린터 유지 확인 완료 |
| QMK | 실제 사용 장치 | 다음 펌웨어 업로드 때 일반 사용자 권한으로 성공 확인. 입력 장치 그룹 복원은 불필요 |
| 공통 수정 적용 | galaxy-book, nxtp-office-desktop | `ns` 후 재부팅. PipeWire 충돌·D-Bus 중복 경고 없음, 소리·입력 정상, `id`에 input/uinput 없음 확인. Galaxy Book은 터치패드도 확인 |
| 프린터 수정 적용 | galaxy-book | 5분 타이머 없음, 재부팅 후 큐·기본 프린터 유지 확인 |

검증한 호스트만 완료 처리합니다. 완료 후 해당 행을 제거하고 아래에 제목만 남깁니다.

## 유지할 참고사항

- 프린터는 AI 호스트·Galaxy Book만 사용. DHCP 예약 주소 `192.168.45.173`. 오프라인 부팅으로 등록 실패 시 연결 후 `sudo systemctl start canon-mf667cx-printer`.
- D-Bus 로컬 패치: `modules/core/dbus.nix`, `dbus-same-service-file.patch`. upstream 해결 시 제거 검토. 회귀 검증은 `checks/dbus-service-dedup.py`. 활성 세션에서 D-Bus를 재시작하지 않습니다.
- WireGuard 단일 장치 공유 접속, SSH 비밀번호 인증, Nix trusted-users는 사용자 유지 결정. 정책 변경·새 증거 없이 문제로 재등록하지 않습니다.
- 정상 종료 직전 잠깐 나오는 watchdog 경고는 조치 제외.

## 완료 — ai-x1-pro

- GDM PipeWire 충돌 해결
- NVIDIA USB-C 초기화 오류 해결
- WebUI·LLM 서비스 및 전용 설정 제거
- 입력 상시 권한 제거 및 키보드·마우스·단축키 확인
- NVIDIA 전역 환경 변수 정리 및 화면·Noctalia·브라우저·영상 확인
- DP 절전 복귀 60Hz 우회·약한 blur 사용자 시험 완료 (자동 꺼짐 15분)
