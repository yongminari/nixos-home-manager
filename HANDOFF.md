# System Review Handoff

최종 갱신: 2026-11-06. 완료 항목은 제목만 유지하고, 상세 이력은 Git에서 확인합니다.

## 남은 검증

| 항목 | 대상 | 다음 확인 |
|---|---|---|
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
