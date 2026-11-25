# System Review Handoff

최종 갱신: 2026-11-25. 완료 항목은 제목만 유지하고, 상세 이력은 Git에서 확인합니다.

## 모듈별 미사용 코드 점검

전체 목록과 진행 상태는 [TODO](docs/TODO.md#모듈별-미사용-코드-점검)에 기록합니다.

**다음 회차**는 [codex-telegram-secrets.nix](modules/services/codex-telegram-secrets.nix)입니다. 비밀의 선언과 서비스 소비 경로를 대조합니다.

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
