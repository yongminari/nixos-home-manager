# System Review Handoff

## 다음 작업 요약 (2026-11-06)

- 조사·개선 후보: 공통 `input`·`uinput` 권한의 사용처, AI 호스트 전역 NVIDIA 환경 변수.
- 사용자 기능 확인 대기: D-Bus 파일 선택·화면 공유·키링 실제 사용, 프린터 실제 인쇄.
- 다른 호스트 적용 대기: Galaxy Book·회사 데스크톱의 공통 PipeWire/D-Bus 수정, Galaxy Book의 프린터 변경. 각 호스트에서 `ns` 후 재부팅·검증하고 결과를 기록합니다.
- AI 호스트 완료: PipeWire 충돌 해소, NVIDIA USB-C 오류 해소, 로컬 AI 제거. D-Bus 중복 경고는 재부팅 후 0건·API 응답 확인 완료.
- 유지 결정: WireGuard 단일 장치 공유 접속, SSH 비밀번호 인증, Nix trusted-users. 정책 변경 요청이나 새로운 증거 없이 미해결 문제로 재등록하지 않습니다.
- 현재 AI 호스트 부팅·적용 세대: `dmnfhr5h2p8wvmm293rxbcgxlqh51bz6`. 아래 이전 세대 표기는 검증 당시의 이력입니다.

## 재부팅 후 검증 결과 (2026-11-06 12:47 KST, ai-x1-pro)

부팅된 시스템과 현재 시스템 모두 `64nyg2qrbyw584xd2p4bwr474xcs3pjf` 세대입니다. 이 절은 해당 시점의 검증 이력이며 최신 D-Bus 검증 결과는 문서 하단을 참고합니다.

- **NVIDIA USB-C: AI 호스트 해결 확인 완료.** `i2c_nvidia_gpu`·`ucsi_ccg` 미로드, UCSI/I²C 시간 초과 및 NVIDIA Xid 로그 없음. `nvidia-smi`에서 RTX 2070 SUPER 인식과 Niri/Noctalia GPU 사용 확인. DP-10은 5120×2160@120Hz로 동작. HDMI-A-2는 감지되지만 기존 설정대로 비활성 상태이므로 실제 HDMI 출력은 미검증. 사용자가 재부팅 후 화면 이상 없음과 소리 정상을 확인했습니다. 사용하지 않는 보조 HDMI 출력 및 모니터 전원 전환은 별도 시험하지 않았으며, 현재 증상의 해결 확인과 구분합니다.
- **PipeWire: AI 호스트 해결 확인 완료.** 현재 부팅 로그에 x11-bell 오류·PipeWire 코어 덤프 없음. PipeWire/pipewire-pulse/WirePlumber 정상. Chrome 오디오 스트림이 모니터 출력에 active로 연결됨. 사용자가 실제 소리 정상을 확인했습니다. 마이크·Noctalia 개별 조작은 별도 시험하지 않았습니다. 다른 호스트 적용은 미확인.
- **로컬 AI 제거: 재부팅 검증 완료.** GTT 전용 커널 인자 없음. 세 서비스 비활성, 8080/4000/11434 수신 없음.
- **프린터: AI 호스트 재부팅 후 설정 유지 확인.** 갱신 타이머 없음, 등록 서비스 성공, 큐 주소 192.168.45.173 및 기본 프린터 유지. 실제 인쇄와 Galaxy Book 적용은 미확인.
- 시스템·사용자 실패 서비스 모두 0개. NixOS 적용 버전·flake.lock·공식 unstable 리비전 일치.

## 점검 상태 관리 (2026-11-06)

수정·빌드 성공과 실제 동작 검증 완료를 구분합니다. 다음 작업 시작 시 이 문서의 검증 대기 항목을 확인하고, 해당 호스트에서 확인 날짜·결과를 기록한 뒤에만 완료 처리합니다. 과거 코어 덤프가 남아 있다는 이유만으로 재발로 판단하지 않습니다. 원격 호스트는 직접 확인하기 전까지 적용 완료로 표시하지 않습니다.

### AI 호스트 완료 / 다른 호스트 검증 대기: GDM PipeWire 충돌

- 범위: 공통 데스크톱 설정, 세 호스트의 GDM 로그인 화면 계정에만 적용.
- 원인 증거: `ai-x1-pro`에서 `gdm-greeter`의 PipeWire 1.6.9가 로그인 화면 종료 시 `x11-bell`의 X11 연결 해제 경로에서 SIGSEGV. 일반 사용자 오디오는 정상.
- 수정: `modules/desktop/nixos-desktop.nix`에서 `gdm-greeter` 및 `gdm-greeter-2`~`-5`에만 `module.x11.bell=false` 적용.
- 완료한 검증: 세 호스트 Flake 검사, `nh os build .`, 격리된 PipeWire 프로세스에서 계정별 규칙 검증 통과.
- 적용: `ai-x1-pro`에서 `nh os switch .` 완료. 일반 사용자 오디오 서비스 정상, 실패 서비스 0개.
- AI 호스트는 재부팅·로그인 후 충돌 미발생 및 사용자 청취 정상 확인 완료. `galaxy-book`과 `nxtp-office-desktop` 적용·검증은 대기.

다음 재부팅 후 로그인한 뒤 확인:

```console
hostname
cat /etc/pipewire/pipewire.conf.d/90-gdm-disable-x11-bell.conf
systemctl --user is-active pipewire pipewire-pulse wireplumber
journalctl -b --no-pager -g 'mod.x11-bell|pipewire.*(dumped|SEGV)|Process.*pipewire'
coredumpctl list --since today --no-pager pipewire
```

재부팅 없이 로그아웃/로그인했다면 전환 전 시각을 기록하고 `journalctl --since '<전환 전 시각>'` 및 `coredumpctl list --since '<전환 전 시각>' pipewire`로 새 기록만 확인합니다. Noctalia 음량·음소거, 실제 소리 재생, 필요한 마이크 입력도 확인합니다. **새 GDM PipeWire 충돌 없음 + 사용자 오디오 정상**을 확인한 호스트만 완료로 표시합니다. 다른 호스트는 각 장치에서 `ns` 적용 후 같은 절차로 확인합니다.

### 검증 대기: Canon 프린터 주기적 재설정 제거

- 범위: `ai-x1-pro`, `galaxy-book`만 사용. 회사 데스크톱에는 이 프린터를 등록하지 않음.
- 사용자 확인: 공유기 DHCP 예약 목록 등록 확인. IP `192.168.45.173`, MAC `20:0B:74:CF:BB:D5`.
- 수정: 5분 갱신 타이머 제거. 부팅 시 큐가 없거나 주소가 다를 때만 등록·수정하고 기존 옵션과 기본 프린터 선택 보존.
- 완료한 검증: Flake 검사, 기존 큐·주소 변경·최초 등록 분기 검증, AI 호스트 시스템 빌드.
- 적용: `ai-x1-pro`에 적용 완료. 타이머 제거, 등록 서비스 성공, 큐 주소 확인.
- 재부팅 후 큐·기본 프린터 유지 확인 완료. 실제 인쇄 및 `galaxy-book` 적용은 미확인.

각 대상 호스트에서 적용 후 확인:

```console
systemctl list-timers --all --no-pager | rg canon
systemctl show canon-mf667cx-printer.service -p Result -p ExecMainStatus
lpstat -v
lpstat -d
```

타이머 검색 결과는 없어야 합니다. 프린터 연결 상태에서 실제 한 페이지를 인쇄하고, 다음 부팅에도 큐·기본 프린터 선택이 유지되는지 확인합니다. 최초 등록 당시 프린터가 오프라인이었다면 연결 후 `sudo systemctl start canon-mf667cx-printer`로 재시도합니다. **두 호스트의 적용과 실제 인쇄 확인 전까지 전체 완료 처리하지 않습니다.**

### 미해결 문제 및 개선 후보

| 번호 | 범위 | 항목 | 상태 |
|---|---|---|---|
| 9 | 공통 | 입력 장치 접근 권한 검토 | 개선 후보, 정책 결정 전 |
| 10 | AI 호스트 | AMD/NVIDIA 혼합 환경의 전역 NVIDIA 변수 | 개선 후보, 장애 미확정 |

D-Bus 중복 이름 경고는 AI 호스트에서 수정·재부팅 후 0건 확인 완료. 실제 앱 기능 확인과 다른 호스트 적용만 남았습니다.

조치 제외: 정상 종료 직전 잠깐 나오는 watchdog 경고. WireGuard 주소·키 공유는 한 번에 한 장치만 접속하는 의도된 정책이며 문제로 재등록하지 않습니다.

SSH 정책 확인 완료: 사용자는 모든 접속 장치의 키 로그인을 확인했고 개인키는 각 장치에 보관합니다. 키가 없는 새 장치의 공개키 등록을 위해 비밀번호 로그인도 의도적으로 허용합니다. 비밀번호 인증 유지 자체를 미해결 오류로 재등록하지 않습니다. 실제 노출·공격 증거 또는 사용자의 정책 변경 요청이 있으면 재검토합니다. SSH 설정값은 변경하지 않았습니다.

## 로컬 AI 서비스 제거 — 적용·재부팅 검증 완료

2026-11-06 사용자는 WebUI·LLM 서비스를 제거하고 필요할 때 새로 구성하기로 했으며, 기존 WebUI 대화·업로드 데이터 폐기에도 명시적으로 동의했습니다. 기존 1~7번 문제는 서비스 제거로 종료합니다.

- 제거: Ollama/Open WebUI/LiteLLM 컨테이너 정의, LiteLLM YAML, AI 호스트 TCP 8080 허용, 전용 ROCm ICD, `amdgpu.gttsize=65536`, Ollama 디렉터리 생성 규칙.
- 유지: 일반 개발용 Podman/Distrobox, NVIDIA 드라이버·컨테이너 툴킷. `/var/lib/ollama`와 로컬 이미지는 별도 삭제하지 않았습니다.
- 검증: `nh os build .`, 세 호스트 Flake 검사 통과. 평가된 컨테이너 정의 `{}`, 허용 TCP 포트 `[22]`, GTT 전용 인자 제거 확인.
- 적용: `ai-x1-pro`에서 `nh os switch .` 성공. 세 서비스 비활성, 8080/4000/11434 수신 없음, 실패 서비스 0개 확인.
- 데이터: 백업 없이 기존 서비스 종료·컨테이너 제거 경로를 실행했습니다. 영구 데이터나 이미지의 완전 삭제를 수행·검증한 것은 아닙니다.
- **재부팅 검증 완료:** `/proc/cmdline`에서 GTT 전용 인자 제거 및 세 서비스·포트 비활성 유지 확인.

```console
cat /proc/cmdline
systemctl is-active podman-ollama podman-litellm podman-open-webui
ss -lnt | rg ':(8080|4000|11434)\b'
systemctl --failed --no-pager
```

나중에 재구성할 때에는 기존 평문 키를 재사용하지 않고 sops로 새 키를 관리하며, 영속 볼륨·접근 제한·고정 이미지 버전·일관된 컨테이너 네트워크를 처음부터 설계합니다. 과거 파일은 Git 이력에 남아 있지만 그대로 복원해 적용하지 않습니다.

## NVIDIA USB-C 초기화 오류 — AI 호스트 해결 확인 완료

- 대상: `ai-x1-pro`만. 사용자가 RTX 2070 SUPER에 외부 USB-C 포트가 없음을 확인했습니다.
- 증거: `c5:00.3` → `i2c_nvidia_gpu` → `ucsi_ccg`에서 I²C 시간 초과(-110). 화면 출력 기능 `c5:00.0`은 별도 `nvidia` 드라이버 사용.
- 수정: 호스트 설정에 `boot.blacklistedKernelModules = [ "i2c_nvidia_gpu" ];` 추가. 전체 I²C, `ucsi_ccg`, NVIDIA 그래픽 드라이버는 차단하지 않습니다.
- 2026-11-06 `nh os build .` 및 `nh os boot .` 성공. 세 호스트의 모듈 목록 평가에서 AI 호스트에만 차단이 추가됨을 확인했습니다.
- 이후 사용자 재부팅 완료. 오류 미발생·GPU 인식·DP 출력 및 오디오 스트림 확인 후 사용자가 실제 소리와 화면 정상을 확인했습니다.
- 예상: 일반 DP/HDMI 화면·오디오와 OCuLink PCIe 연결은 이 모듈의 담당 기능이 아닙니다. 실제 dock 구성에서 재부팅 후 GPU 인식·DP 화면·오디오 정상 확인을 완료했습니다.

```console
hostname
lsmod | rg 'i2c_nvidia_gpu|nvidia'
journalctl -b -k --no-pager | rg 'nvidia-gpu|ucsi_ccg|i2c timeout|NVRM|Xid'
nvidia-smi
```

완료 기준: `i2c_nvidia_gpu` 미로드, 기존 UCSI 시간 초과 없음, OCuLink eGPU 인식·DP/HDMI 화면·주사율·모니터 오디오 정상. 호스트의 시스템 절전은 비활성화되어 있으므로 검증을 위해 새로 활성화하지 않습니다. 실제 사용하는 모니터 꺼짐/켜짐도 확인합니다. 문제 발생 시 이전 NixOS 세대로 부팅하거나 차단 항목 제거 후 `ns` 및 재부팅으로 복구합니다. 확인 날짜·결과를 기록하기 전까지 완료 처리하지 않습니다.

## Nix trusted-users 정책 — 유지 결정 (2026-11-06)

사용자는 개인 관리 계정의 편의를 위해 현재 `trusted-users = [ "root" username ]`을 유지하기로 했습니다. 관리자 수준의 신뢰를 부여한다는 보안 영향을 설명했고, 이후 위험 판단이나 보안 요구가 바뀌면 제거를 검토합니다. 설정값은 변경하지 않았으며 미해결 개선 목록에서 제외합니다. 이는 위험이 없다는 판정이 아닙니다. 재검토 시 비밀번호 없는 시스템 적용 sudo 규칙과 함께 평가합니다. 입력 장치 그룹 권한 검토는 별도 항목으로 남깁니다.

## D-Bus 중복 등록 조사 (2026-11-06, ai-x1-pro)

- 이번 부팅에 중복 이름 경고 192건, 이름 95개 확인. 사용자 세션 설정의 명시적 서비스 경로는 45개 중 고유 경로 41개. GNOME keyring 경로 2회, GNOME portal 3회, GTK portal 2회 등록.
- 시스템 통합 프로필 경로와 개별 패키지 경로가 같은 서비스 파일을 가리키는 경우도 확인했습니다.
- 사용자/시스템 버스를 구분해 비교한 검색 경로에서는 같은 이름의 서로 다른 내용 충돌을 발견하지 못했습니다. systemd portable/import/machine 서비스의 사용자용·시스템용 파일 차이는 별도 버스의 정상적인 구분입니다.
- 시스템·사용자 D-Bus 및 GNOME/GTK 포털 활성, 실패 서비스 0개. 앱별 파일 선택·화면 공유 등 모든 기능을 시험한 것은 아닙니다.
- 판단: 현재 증거는 서비스 실행 충돌보다 중복 검색 경로에 따른 경고를 가리킵니다. NixOS upstream 이슈 #303078에도 같은 종류의 보고가 있습니다.
- 상태: 원인 조사 완료, 설정 미변경. 경고 정리를 진행한다면 공통 D-Bus 서비스 검색 경로의 중복 제거를 검토하되 활성 세션의 D-Bus를 재시작하지 않고 별도 테스트와 다음 로그인 검증을 수행합니다. 단순 로그 숨김이나 서비스 삭제로 해결하지 않습니다.

## D-Bus 동일 파일 중복 등록 정리 — 빌드·다음 부팅 등록 완료

- 공통 설정 `modules/core/dbus.nix`에서 기존 dbus-broker 패치 목록에 `dbus-same-service-file.patch`를 추가합니다. Nixpkgs의 보안 패치는 유지합니다.
- 검색 경로·순서·서비스 정의·권한 정책은 변경하지 않습니다. 중복 이름을 발견했을 때 기존 항목과 새 항목의 `realpath`가 같으면 동일 파일의 재발견으로 처리합니다. 서로 다른 파일이면 기존 충돌 경고를 유지합니다. 단순 로그 필터링이 아닙니다.
- 경로 목록만 정리하면 사용자 프로필 및 시스템 통합 경로와의 중복을 모두 제거하기 어려워 로더에서 동일 파일을 중복 제거하는 방식으로 구현했습니다. 로컬 패치 유지 비용이 있으며 upstream 해결 시 제거해야 합니다.
- 격리된 버스 검증 통과: 동일 파일 symlink 중복은 원본에서 경고/수정본에서 경고 없음; 서로 다른 파일의 이름 충돌은 양쪽 모두 경고. 현재 사용자 session.conf로 실행한 원본/수정본의 활성화 가능 서비스 목록 동일, 경고 125건→0건.
- 재실행 가능한 수동 검증: `python3 checks/dbus-service-dedup.py ORIGINAL_LAUNCHER PATCHED_LAUNCHER`. 로그인된 사용자 세션에서 실행하며 임시 소켓만 사용합니다.
- `nh os build .` 및 세 호스트 Flake 검사 통과. `ai-x1-pro`에서 `nh os boot .` 성공. 현재 세션의 D-Bus는 교체·재시작하지 않았습니다.
- **검증 대기:** 다음 재부팅·로그인 후 실제 시스템/사용자 버스 중복 경고, 포털 및 키링 기능을 확인해야 합니다. Galaxy Book·회사 데스크톱은 미적용입니다.

```console
journalctl -b --no-pager -g 'Ignoring duplicate name'
systemctl is-active dbus
systemctl --user is-active dbus xdg-desktop-portal xdg-desktop-portal-gnome xdg-desktop-portal-gtk
systemctl --failed --no-pager
systemctl --user --failed --no-pager
```

파일 선택 대화상자·화면 공유·키링 사용도 확인합니다. 새 경고가 없고 실제 기능이 정상임을 확인한 뒤 완료 처리합니다. 문제가 있으면 이전 세대로 부팅하거나 `modules/core/nixos-base.nix`의 dbus.nix import를 제거해 upstream 패키지로 복귀합니다. 활성 세션에서 D-Bus를 직접 재시작하지 않습니다.

## D-Bus 재부팅 검증 (2026-11-06, ai-x1-pro)

- 부팅·현재 시스템 모두 `dmnfhr5h2p8wvmm293rxbcgxlqh51bz6` 세대. 시스템/사용자 버스 모두 수정한 `qm6101ckl3ygxkhnz5xj0ndsqhzckfl2-dbus-broker-37` 실행 확인.
- **실제 부팅·로그인에서 중복 이름 경고 0건.** 시스템·사용자 실패 서비스 0개.
- GNOME/GTK/메인 포털 활성. D-Bus 속성 호출로 FileChooser v4, ScreenCast v5 응답 확인.
- 키링은 별도 사용자 systemd 서비스가 아닌 로그인 세션 프로세스로 실행 중이며 `org.freedesktop.secrets`·`org.gnome.keyring` 이름 소유 확인. Secret.Service Collections 조회 정상(키나 비밀값은 읽지 않음).
- `home1`·`resolve1` 활성화 실패 경고는 이전 부팅에도 있었으며 해당 선택 서비스는 설치/활성화되지 않음. 이번 중복 제거 패치로 새로 발생한 현상은 아닙니다.
- **상태:** AI 호스트 중복 경고 제거 및 서비스/API 검증 완료. 실제 앱의 파일 선택·화면 공유·저장된 인증정보 사용은 사용자 기능 확인 대기. 다른 두 호스트 적용은 미확인.
