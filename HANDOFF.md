# System Review Handoff

최종 갱신: 2026-11-25. 완료 항목은 제목만 유지하고, 상세 이력은 Git에서 확인합니다.

## 모듈별 미사용 코드 점검

전체 목록과 진행 상태는 [TODO](docs/TODO.md#모듈별-미사용-코드-점검)에 기록합니다.

**모듈별 점검 52개를 모두 완료했습니다.** 보류한 Niri 효과 분리를 재개할 때는 [TODO의 분리 범위 확정](docs/TODO.md#niri-효과의-별도-오픈소스-프로젝트-분리)부터 진행합니다. 정리 후보와 장치별 실사용 검증은 아래 회차 기록 및 남은 검증 표에 있습니다.

### 2026-11-25 · 공통 홈 설정

- 세 호스트 각각에서 통합·독립 Home Manager 구성이 공통 계정·홈 디렉터리·상태 버전, 별칭, 이 파일에서 선언한 세션 변수, glab 링크 대상과 Antigravity 키 설정에 대해 일치합니다. `QSG_RHI_BACKEND=opengl`은 NVIDIA 호스트 두 대에서만 생성됩니다. 최상위 모듈 인자 다섯 개가 모두 사용됩니다.
- 현재 PC의 사용자 서비스 환경과 생성된 셸 설정을 확인했습니다. Bash·Zsh 및 설치 설정을 읽은 Nushell에서 `hms`·`ns`가 의도한 nh 명령으로 확장됩니다. glab 링크는 렌더링된 파일과 동일 대상을 가리키며, Antigravity 키 설정은 평가 결과와 일치합니다. 홈 빌드는 적용된 세대와 같은 결과를 냈습니다. 이번 회차에는 점검 문서만 변경했습니다.

### 2026-11-25 · 사무실 데스크톱과 검증·Flake 진입점

- **시스템 설정** — 실제 유선 IPv4 주소 두 개와 테스트망 정적 경로가 선언과 일치합니다. 경로 조회 시 1.1.1.1은 enp13s0, 192.168.1.1은 enp6s0f3를 선택했습니다. 다만 두 유선 인터페이스 모두 metric 100의 기본 경로를 가지고 있고 보조망 NetworkManager 프로필에도 게이트웨이가 있어 회사망 우선순위가 고유하지 않습니다. 네트워크는 변경하지 않았습니다. NVIDIA 모듈·fbdev 커널 인자와 sleep/suspend 타깃 마스킹을 확인했습니다.
- **하드웨어 설정** — 실제 루트(ext4)와 EFI(vfat)의 UUID가 선언과 일치하고 활성 스왑이 없으며 kvm_amd가 로드돼 있습니다. 미사용 인자 `pkgs`는 자동 생성 파일에 있어 보존합니다.
- **홈 설정** — 통합·독립 구성의 Noctalia 배율·잠금 화면 배치·GPU 환경변수가 일치합니다. Niri 실측에서 DP-2는 왼쪽, DP-3는 오른쪽이며 모두 2560×1440, 약 120Hz, 배율 1입니다. 호스트 기본 배율 중복은 앞선 회차에 기록했습니다.
- **checks/default.nix·flake.nix** — Flake가 NixOS·독립 홈 구성을 각각 세 개, 체크를 11개 제공합니다. `nix flake check --no-write-lock-file`이 통과했습니다. `outputs`의 명시적 인자 `noctalia`는 직접 참조되지 않아 정리 후보입니다. Noctalia 입력 자체는 모듈에서 `inputs.noctalia`로 사용합니다. 이번 회차는 문서만 변경했습니다.

### 2026-11-25 · ai-x1-pro와 Galaxy Book 호스트 설정 5개

- **두 하드웨어 설정** — 최종 루트·EFI·스왑 장치 경로가 각 선언과 일치합니다. ai-x1-pro는 kvm-amd 및 AMD 마이크로코드, galaxy-book은 kvm-intel 및 Intel 마이크로코드를 선택합니다. 두 자동 생성 파일의 인자 `pkgs`는 미사용이지만 재생성 가능한 파일이라 그대로 둡니다.
- **ai-x1-pro 홈** — 통합·독립 구성에서 Noctalia 배율 1.5, XWayland/GLX용 Sioyek 래퍼, 외부 모니터 배치와 유휴 주사율 설정이 일치합니다. 기본 배율 1.0과 화면 꺼짐 900초는 이전에 확인한 공통 기본값이며, 모니터별 1.25배 설정은 별개입니다.
- **Galaxy Book 시스템** — 세 호스트 중 이 장치에만 BAT1의 충전 상한 속성이 있을 때 90을 쓰는 udev 규칙이 생성됩니다. `configuration.nix`에서 미사용 인자 `config`와 `pkgs`를 제거했습니다. 변경 전후 Galaxy Book의 NixOS 시스템 derivation 경로가 일치했습니다.
- **Galaxy Book 홈** — 통합·독립 구성에서 Noctalia 배율 1.15와 노트북 입력 분기가 일치하고 터치패드 초기화 훅이 생성됩니다. 기본값을 반복하는 `scale`, `outputs`, `extraConfig`는 이전 점검과 같은 후보입니다.
- 두 호스트의 Niri 구성 체크와 터치패드 상태 체크가 통과했습니다. 현재 작업 기기는 nxtp-office-desktop이며 대상 장치의 부팅·충전·디스플레이는 실측하지 않았습니다.

### 2026-11-25 · 시스템 유틸리티·테마·주변기기·AI 호스트

- **시스템 유틸리티** — 통합·독립 Home Manager 평가에서 NVIDIA 데스크톱 두 대만 btop 래퍼를, galaxy-book은 기본 btop을 선택합니다. nh 래퍼와 종료 메뉴는 공통이며 Niri의 Mod+Shift+E와 Mod+V가 각각 wlogout과 클립보드 기록에 연결됩니다. 현재 PC에서 nh·btop의 실행 래퍼와 클립보드 서비스 두 개의 실행을 확인했습니다.
- **테마** — 여섯 구성에서 GTK 테마·Qt 스타일과 커서 이름·크기가 일치합니다. 현재 PC의 GTK 3 설정에서도 adw-gtk3-dark·Papirus-Dark·Bibata-Modern-Ice(48)를 확인했습니다. 다른 툴킷과 레거시 앱용 설정은 각기 다른 적용 경로입니다.
- **프린터** — CUPS는 세 호스트 공통이고 스캔 및 Canon 큐 등록은 ai-x1-pro·galaxy-book에만 활성화됩니다. 두 호스트의 등록 스크립트가 같고, 모의 CUPS 명령으로 최초 등록 및 기본값 설정, 기존 큐·기본값 보존, 주소만 바뀐 경우의 갱신을 확인했습니다. 실제 인쇄는 기존 검증 항목입니다. 본문에서 사용하지 않는 모듈 인자 `config`는 정리 후보입니다. `services.printing.enable`은 공통 데스크톱에도 있지만 프린터 모듈 자체의 전제이므로 유지할 수 있습니다.
- **Galaxy Book 하드웨어** — galaxy-book에만 thermald·auto-cpufreq 및 KT LTE 프로필이 활성화됩니다. 스피커·백라이트 커널 인자와 ModemManager 종료 정책은 장치별 설정입니다. LTE 접속이나 배터리 전환은 이번 회차에서 실기 시험하지 않았습니다.
- **ai-x1-pro 시스템** — 최종 구성에서 NVIDIA PRIME 오프로딩·컨테이너 툴킷 활성화, sleep 타깃 비활성화와 느슨한 역방향 경로 검사를 확인했습니다. 실제 GPU 작업과 절전 전환은 실행하지 않았습니다. 이번 묶음은 문서만 갱신했습니다.

### 2026-11-25 · 공통 시스템 모듈 5개

- **컨테이너** — 세 호스트의 Podman·Docker 호환 설정과 기본 네트워크 DNS 설정이 일치합니다. 현재 PC에서 Podman 사용자 소켓이 응답하고 Distrobox·fuse-overlayfs가 설치돼 있습니다. 모듈 인자 `config`는 본문에서 참조하지 않습니다.
- **D-Bus** — 세 호스트가 같은 패치된 broker를 선택합니다. 현재 PC의 세션 설정으로 별도 버스에서 회귀 테스트한 결과 원본의 중복 경고 129건이 패치 적용 시 0건이었고 활성화 가능한 서비스 목록은 같았습니다. 서로 다른 파일의 실제 충돌에는 양쪽 모두 경고했습니다.
- **글꼴** — 여섯 Home Manager 구성에서 기본 글꼴 목록과 한글 대체 규칙이 일치합니다. 현재 PC의 Fontconfig는 monospace에 Maple Mono NF, Maple Mono NF가 요청된 한글 ‘가’에는 Jalpullineunoneul을 선택했습니다.
- **NixOS 기본 설정** — 세 호스트의 부트로더 활성화, 커널 버전, 기본 로케일, SSH 설정, GC 보존 옵션, QMK 설정 및 펌웨어 옵션을 비교했습니다. 고정 nixpkgs에서 `enableRedistributableFirmware`의 기본값은 `enableAllFirmware`입니다. 중복된 전자의 명시적 선언을 제거했습니다. 세 호스트 모두 변경 전후 펌웨어·CPU 마이크로코드 값과 NixOS 시스템 빌드 경로가 일치했고, nxtp-office-desktop에서 시스템 빌드를 검증했습니다.
- **비밀 관리** — 세 호스트의 GitLab 토큰 선언 및 glab 템플릿 소유자·모드가 일치합니다. 현재 PC에서 토큰 파일은 0400, age 키와 렌더링된 glab 설정은 0600이고 소유자는 사용자입니다. 내용 열람이나 인증 요청 없이 메타데이터를 확인했습니다.

### 2026-11-25 · 데스크톱 4개 모듈과 사내 CA

- **유휴 blur** — 통합·독립 Home Manager 구성에서 ai-x1-pro에만 오버레이 서비스와 초기화 훅이 생성됩니다. 주사율 도우미가 서비스를 제어하고 Niri 레이어 규칙이 해당 namespace를 사용합니다. AI 호스트의 Niri 구성 및 주사율 체크가 통과했습니다. 실기 잠금 화면에서의 시각적 검증은 기존 보류 항목입니다.
- **Kitty** — 여섯 구성의 생성 설정과 셰이더 소스가 같고 현재 PC의 설정 파일도 일치합니다. 설치된 `ghostty-effects.pipeline`이 배포된 Slang 셰이더 7개 모두를 참조합니다. 이 회차에서는 GPU 렌더링을 시험하지 않았습니다.
- **NixOS 데스크톱** — 세 호스트의 GDM·GNOME·Niri, 파일 선택 포털, 입력기 종류, 기본 고정폭 글꼴 및 GDM 전용 PipeWire 예외를 비교했습니다. 현재 PC에서 Niri 파일 선택 포털은 GTK이고 PipeWire·WirePlumber·포털 서비스가 실행 중입니다.
- **Swappy** — 여섯 구성에서 설정과 스크린샷 디렉터리 생성 훅이 일치합니다. Niri의 Print·Shift+Print가 Swappy를 호출하며 현재 PC에 실행 파일과 저장 디렉터리가 있습니다. 모듈 인자 `pkgs`와 `lib`는 참조하지 않습니다. 활성화 훅은 `mkdir -p`를 직접 호출하므로 Home Manager의 `run`을 쓰도록 정리하면 dry-run에서도 디렉터리 생성을 건너뛸 수 있습니다.
- **사내 CA** — 세 호스트의 최종 시스템 설정에 같은 인증서가 포함되고 현재 PC의 시스템 CA 번들에서 인증서 바이트가 일치했습니다. 사내 서버 접속은 시험하지 않았습니다. 이번 묶음은 문서만 변경했습니다.

### 2026-11-25 · 유휴 화면 및 잠금

- 각 호스트의 통합·독립 Home Manager 설정과 시작 전 명령이 일치합니다. 모두 600초에 잠그고 900초에 화면을 끕니다. galaxy-book만 540초에 밝기를 낮추고 서비스 시작 전 미복원 밝기를 복구합니다. ai-x1-pro만 885초에 주사율·blur 준비를 수행합니다.
- nxtp-office-desktop에서 생성된 설정과 설치본이 일치하고 서비스가 실행 중입니다. 설치된 포커스 도우미를 임시 상태 디렉터리와 모의 Niri로 실행해 기존 창 복원과 창이 사라졌을 때 모니터 복원을 확인했습니다.
- 밝기·주사율 Nix 체크가 통과했습니다. ai-x1-pro의 두 타이머는 서로 다른 유휴 단계에서 활동이 돌아올 때 같은 복귀 명령을 사용하며, 중복 복귀는 회귀 테스트에 포함돼 있습니다. 제거 후보는 없습니다. 실제 잠금·절전·화면 전원 전환은 실행하지 않았습니다.

### 2026-11-25 · 호스트별 데스크톱 옵션

- 선언한 모든 옵션의 사용처를 Niri, Noctalia, 유휴 화면 처리, Chrome 설정에서 확인했습니다. 각 호스트의 통합·독립 Home Manager 평가 결과는 서로 일치합니다. 세 호스트 모두 창 닫기 효과는 genie, 모니터 자동 꺼짐은 900초입니다. ai-x1-pro는 유휴 주사율·blur 옵션을 활성화하며 galaxy-book만 노트북 입력 분기를 사용합니다.
- 정리 후보는 호스트 파일에서 공통 기본값을 반복한 선언입니다. 세 호스트의 `scale = "1.0"`, galaxy-book의 `outputs = null`과 `extraConfig = ""`, ai-x1-pro의 `monitorOffTimeout = 900`이 해당합니다. 실제 모니터별 배율·배치와 유휴 처리 예외는 별도로 사용됩니다.

### 2026-11-25 · GUI 앱

- 세 호스트의 통합·독립 Home Manager 구성 여섯 곳에서 기본 앱 연결 11개와 Sioyek 설정·키 바인딩이 일치합니다. 현재 PC에서 앱 7개의 실행 경로와 `xdg-mime query default` 결과를 확인했습니다. PDF는 Sioyek, 이미지 5종은 Loupe, HTML과 URL 스킴 4개는 Chrome입니다. ai-x1-pro는 NVIDIA 호환성을 위해 Sioyek 실행 파일과 런처에 XWayland·GLX 래퍼를 사용합니다.
- Chrome에 인자 목록을 항상 전달하도록 빈 목록 전용 조건문을 제거했습니다. 여섯 구성의 변경 전후 Chrome 패키지 경로와 데스크톱 옵션이 일치합니다. 현재 PC에서 홈 빌드를 통과했고 적용된 세대와 같은 결과를 얻었습니다.

### 2026-11-25 · Ghostty

- 세 호스트의 통합·독립 Home Manager 구성 여섯 곳에서 패키지, 설정, 셸 통합, 셰이더·런처·종료 설정 파일 경로가 일치합니다. 현재 PC에서 `ghostty +validate-config`가 통과했고 `+show-config`에 표시된 셰이더 6개가 모두 설치돼 있습니다. 종료 설정은 Ghostty 터미널 scope에 SIGHUP과 10초 제한을 지정합니다.
- 배포한 셰이더 10개 중 4개는 현재 선택되지 않았습니다. 그중 `ambient_aurora.glsl`은 저장소에서 배포 선언 외의 참조가 없으며, 터미널 셰이더 분리 검토 대상으로 보존합니다. 이번 점검은 실제 GPU 렌더링이나 종료 동작을 재현하지 않았습니다.

### 2026-11-25 · Neovim

- 세 호스트의 통합·독립 Home Manager 구성 여섯 곳에서 Neovim 래퍼, 별칭·기본 편집기 옵션, 초기화 코드와 Lua 파일 네 개가 일치합니다. 현재 PC에서 설치본을 대조하고 Neovim 0.12.6의 헤드리스 세션으로 확인했습니다. 로컬과 모의 SSH 모두 Ayu를 로드했고, 일반 원격 터미널에서 OSC52와 불투명 배경 분기가 선택됐습니다. 임시 Nix 파일에서 nil_ls 연결, 버퍼 전용 정의 이동 키, Tree-sitter 파싱과 Telescope 키 바인딩도 확인했습니다.
- 사용하지 않는 Nix 인자 `config`, Lua의 `theme_style` 계산·반환, `utils.is_ssh` 반환 필드와 LspAttach의 지역 변수 `opts`를 제거했습니다. 현재 PC에 홈 설정을 빌드·적용한 뒤 모의 SSH에서 원격 판별과 OSC52, 임시 Nix 파일에서 nil_ls 연결 및 버퍼 키 등록을 검증했습니다.
- Obsidian 보관함이 있을 때만 초기화와 두 단축키 등록을 수행합니다. 적용된 설정을 임시 홈에서 실행해 보관함이 없을 때 두 키가 비어 있고, 보관함이 있을 때 초기화 후 새 노트·검색 키가 등록되는 것을 확인했습니다.

### 2026-11-25 · Git

- 세 호스트의 통합·독립 Home Manager 구성 여섯 곳에서 Git·LFS·Delta·LazyGit·GitUI의 패키지와 모듈 설정이 일치합니다. 현재 PC의 임시 저장소에서 기본 브랜치 main, 작성자 설정, Git LFS 포인터 생성과 원본 복원, 설정된 Delta로 staged diff 출력을 검증했습니다.
- Neovim에서 `<leader>G`가 LazyGit 명령에 연결되며, GitUI는 README에서 별도 수동 도구로 안내합니다. 설치된 GitUI 키맵을 평가 결과와 대조하고 0.28.1 소스에서 동작을 확인했습니다. README에 스테이징 해제로 적혀 있던 `Shift+U`는 작업 트리 변경 폐기에 연결되고 스테이징 목록의 해제 키는 `Enter`여서 설명을 수정했습니다.
- 사용하지 않는 모듈 인자 `config`와 `pkgs`를 제거했습니다. LazyGit 로그 그래프는 `git.log.showGraph = "always"`로 명시합니다. 세 호스트의 통합·독립 Home Manager 구성 여섯 곳에서 변경 전후 활성화 패키지의 derivation 경로가 일치했고, nxtp-office-desktop의 홈 빌드가 통과했습니다.

### 2026-11-25 · 공통 개발 도구

- 세 호스트의 통합·독립 Home Manager 구성에서 이 모듈의 19개 패키지가 각각 한 번씩 포함되며 세 업데이트 명령과 사용자 실행 경로 설정도 일치합니다. 현재 PC에서 패키지별 실행 파일과 설치된 업데이트 스크립트 세 개를 대조했습니다.
- 현재 Neovim에서 설정된 언어 서버 10개의 활성화와 실행 파일 경로를 확인했습니다. QMK에는 별도 사용 가이드와 시스템 장치 규칙이 있습니다. 여러 저장소를 관리하는 vcs2l과 구조적 코드 검색용 ast-grep은 저장소에서 직접 호출하는 곳을 찾지 못했습니다. 개인 사용 빈도는 미확인이므로 삭제 후보로 지정하지 않았습니다.
- 세 업데이트 스크립트의 Bash 구문을 검사했습니다. 모의 하위 명령으로 저장소 및 설치 경로 모두에서 Codex → Antigravity 호출 순서와 첫 명령 실패 시 중단·종료 코드 전달을 확인했습니다. 실제 다운로드와 업그레이드는 실행하지 않았습니다.

### 2026-11-25 · 개발용 컨테이너 도구

- [containers.nix](modules/dev/containers.nix)는 수동으로 실행하는 Podman 관리 도구 `podman-tui`를 설치합니다. README의 CLI 목록에 있으며 저장소에서 자동 호출하는 곳은 발견하지 못했습니다. 세 호스트의 통합·독립 Home Manager 구성 여섯 곳에 같은 패키지가 한 번씩 포함되고, 세 호스트 모두 시스템 설정에서 Podman을 활성화합니다.
- nxtp-office-desktop의 실행 파일은 평가한 패키지와 일치합니다. `podman-tui version`은 v2.0.0을 출력했고 사용자 Podman 소켓의 `/_ping`은 `OK`를 반환했습니다. 실제 사용 빈도는 확인하지 않았으며 삭제 후보 없이 점검을 마쳤습니다.

### 2026-11-25 · Codex

- 세 호스트의 통합·독립 Home Manager 구성 여섯 곳에서 전역 지침과 설정 병합 훅이 동일합니다. 현재 PC의 설치된 지침과 관리 대상 TOML 값도 선언과 일치했습니다.
- 임시 디렉터리에서 실제 훅과 같은 Python 환경으로 새 설정 생성, 기존 모델·MCP 항목·TUI 사용자 키·주석 보존, 관리 값 덮어쓰기, 최초 백업 및 같은 설정 재실행 시 파일 수정 시각 유지를 검증했습니다. 두 선언 모두 활성 경로에서 쓰여 삭제 후보가 없습니다.

### 2026-11-25 · Zsh

- 세 호스트의 통합·독립 Home Manager 구성 여섯 곳에서 생성된 `.zshrc`가 일치합니다. `.zshenv`는 Home Manager 세션 변수 파일의 저장소 경로만 다릅니다.
- 현재 PC의 새 대화형 Zsh에서 fzf-tab·자동 제안·Starship 프롬프트 함수와 위·아래 방향키의 부분 문자열 기록 검색 바인딩을 확인했습니다.
- `.zshenv`에서 내보낸 `ZSH_DISABLE_COMPFIX=true`를 `.zshrc`의 `localVariables`가 같은 값으로 다시 설정하고 있었습니다. 후속 정리에서 후자를 제거했습니다. 여섯 구성에서 중복 제거를 검증하고 nxtp-office-desktop에 홈 설정을 빌드·적용했습니다. 상속값을 지운 새 대화형·비대화형 Zsh에서 값이 true이고, 대화형에서는 export 속성과 위 방향키 바인딩도 유지됨을 확인했습니다.

### 2026-11-25 · Zellij

- 세 호스트의 통합·독립 Home Manager 구성 여섯 곳에서 Zellij 패키지, Bash·Zsh 통합 옵션, 업데이트 명령 패키지, 로컬·원격 KDL이 일치합니다. 현재 PC에 설치된 두 KDL도 평가 결과와 같고 각각 Zellij 0.46.0의 `setup --check`를 통과했습니다. 세 셸의 래퍼가 원격 환경에서 밝은 테마 설정을 선택합니다. Bash·Zsh의 로컬 자동 시작은 공통 셸 스크립트가 담당합니다.
- 기본 레이아웃은 `tab-bar`와 `status-bar`를 참조하고, 두 별칭에 연결된 WASM 파일을 확인했습니다. 잠금 전환은 `Ctrl+Shift+H`로 선언합니다. 키 입력의 실제 전달 여부는 시험하지 않았습니다.
- Zellij 0.46.0이 읽지 않는 `mirror_session_to_terminal_title true`를 제거했습니다. 변경 후 여섯 구성의 로컬·원격 KDL을 비교하고 두 파일의 `setup --check`를 통과했습니다. nxtp-office-desktop에서 홈 빌드 및 `hms` 적용 후 설치본까지 대조했습니다. `default_layout`, `pane_frames`, `simplified_ui`, `mouse_mode`, `copy_on_select`의 값은 배포 기본값과 같습니다.
- 수동 명령 `zellij-update`는 [사용 가이드](docs/nh.md)에 있지만 Flake 입력은 `v0.1.4` 태그로 고정되어 있습니다. 명령을 실행해도 새 버전 태그로 넘어가지 않으므로 최신 정식 릴리스를 가져온다는 설명과 다릅니다. 플러그인 업데이트는 실행하지 않았습니다.

### 2026-11-25 · Yazi

- 세 호스트의 통합·독립 Home Manager 구성 여섯 곳에서 셸 연동, 키맵, 설정, 초기화 코드, 플러그인 패키지와 추가 패키지가 일치합니다. 현재 PC에서는 Bash·Zsh·Nushell 초기화 파일에 디렉터리 이동용 `y`가 생성됩니다.
- Yazi 안에서 누르는 `y`는 선택 파일을 시스템 클립보드에 복사한 후 내부 yank를 실행합니다. 설치된 도우미에 모의 `wl-copy`를 연결해 MIME 유형과 공백·한글·`#`이 있는 두 경로의 URI 인코딩 및 CRLF 구분을 검증했습니다.
- Markdown 미리보기는 `rich-preview`가 `rich-cli`의 `rich`를 실행하고, `full-border`와 `starship`은 설치된 초기화 파일에서 호출합니다. 편집기는 Neovim에 연결됩니다. 확인한 도우미와 플러그인은 모두 사용 경로가 있습니다.

### 2026-11-25 · 셸 환영 메시지와 단축키 도움말

- 세 호스트의 통합·독립 Home Manager 구성에 같은 네 명령이 설치됩니다. Bash·Zsh·Nushell 초기화에서 호출하는 `welcome-msg`는 현재 PC에서 일반 환경이면 출력이 없고, `SSH_CLIENT`가 있으면 원격 배너, `ZELLIJ`가 있으면 Zellij 배너를 표시했습니다. 배너가 없을 때도 실행하는 부모 셸 이름 조회(`ps | sed`)는 표시 조건 안으로 옮길 수 있습니다. 모듈 인자 `config`와 `lib`도 참조하지 않습니다.
- 세 단축키 도움말은 현재 PC에서 직접 실행됩니다. 세 호스트 모두 Niri를 활성화하고 Hyprland는 비활성화하며, 저장소에서 `hypr-cheat`의 자동 호출도 발견되지 않아 삭제 후보입니다. `yazi-cheat`의 열기·검색·종료 키는 설치된 Yazi 기본 키맵과 일치하며, 사용자 지정 `y` 키는 내부 복사와 시스템 클립보드 복사를 함께 수행합니다.
- `niri-cheat`는 [공통 키 바인딩](modules/desktop/niri/binds.kdl)과 네 곳이 어긋납니다. 전체 화면은 `Mod+Shift+F`(`Mod+F`는 열 최대화), 열 너비 조절은 `Mod+-/=`, 영역 캡처는 `Shift+Print`입니다. 종료로 안내한 `Mod+Shift+Q`는 공통 키 바인딩에 없고 `Mod+Shift+E`가 종료 메뉴를 엽니다. 이번 회차는 문서만 변경했습니다.

### 2026-11-25 · 공통 셸 도구

- 세 호스트의 통합·독립 Home Manager 구성에서 공통 별칭, SSH 응답 확인 설정(15초·2회), 로컬·원격 Starship 설정과 셸 도구 연동 옵션이 일치했습니다. 현재 PC의 Bash·Zsh·Nushell 초기화 파일에서 Starship·Zoxide·fzf·Carapace·Atuin·direnv 연결을 확인했습니다.
- `gssh`·`kssh`와 셸의 `ssh` 래퍼가 `ssh-session`을 호출합니다. 현재 PC의 설치본에 로컬 모의 명령을 전달해 파이프 출력과 종료 코드(0·37) 보존, 가상 터미널에서 두 경우 모두 에코 상태 복원을 검증했습니다. 세 셸에서 프로필 전환 후 프롬프트를 확인하는 `starship-profile-switch` 체크도 통과했습니다.
- [utils.nix](modules/core/shell/utils.nix#L1)의 모듈 인자 `config`는 본문에서 참조하지 않아 정리 후보입니다. 이번 회차는 문서만 변경했습니다.

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

- nxtp-office-desktop의 상단 바가 숨은 뒤에도 62px 입력 영역이 남아 10초 후 y=36에서 다시 열리는 것을 추적했습니다. 사용자가 `ns` 후 정상 동작을 확인해 추가 조사를 보류합니다. 정상화 원인은 미확정이며 로컬 패치는 적용하지 않았습니다.

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
