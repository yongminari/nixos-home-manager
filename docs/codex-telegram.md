# Codex CLI 텔레그램 완료 알림

모든 호스트가 같은 봇과 채팅을 사용합니다. 메시지는 `✅ <hostname>: Codex 응답 완료`이며,
대화 내용은 전송하지 않습니다. Codex의 각 응답 턴이 끝날 때 전송하며 기존 Kitty → Noctalia
알림과 함께 동작합니다. 별도 봇 서버나 인바운드 방화벽 포트는 필요 없습니다.

## TODO: 텔레그램에서 특정 Codex 스레드로 지시 보내기

2026-09-24: 사용자 요청으로 추가 구현은 보류하고 TODO로 남깁니다.
완료 알림 구성은 작성 및 빌드 검증까지 진행했으며 현재 비활성 상태입니다.
봇 비밀값 등록, 시스템 적용, 실제 휴대폰 수신 확인은 아직 진행하지 않았습니다.

- [ ] 기존 Kitty의 Codex CLI 세션을 그대로 유지하면서 외부 입력을 전달할 수 있는지 검증
- [ ] 검증 결과에 따라 App Server 연결 방식과 터미널·봇의 세션 공유 방식 결정
- [ ] 모든 PC의 호스트명·스레드 ID·제목·실행 상태를 연결하여 목록과 선택 기능 제공
- [ ] 완료 알림에 답장하면 해당 PC의 해당 스레드로 메시지를 전달하도록 구현
- [ ] 대기 중인 스레드의 대화 재개와 실행 중인 스레드의 추가 지시 처리 구분
- [ ] 허용된 Telegram 사용자만 명령을 보낼 수 있도록 인증 및 대상 확인
- [ ] 여러 PC 간 명령 분배, 중복 처리 방지, 오프라인·재시작 복구 방식 결정
- [ ] PC와 휴대폰에서 스레드 선택·전송·응답 수신을 함께 검증

양방향 연결 애플리케이션은 별도 프로젝트에서 구현하고, 이 저장소에서는
패키지·systemd 서비스·sops 비밀값·영속 저장 경로 등 시스템 구성을 관리합니다.
소요 시간은 기존 CLI 세션 연결 가능성을 검증한 뒤 다시 산정합니다.

## 최초 설정

1. 텔레그램의 [@BotFather](https://t.me/BotFather)에서 `/newbot`으로 봇을 생성합니다.
2. 새 봇과의 개인 대화를 열어 Start를 누릅니다. 안드로이드에서 Telegram 앱과 이 대화의 알림을 허용합니다.
3. 로컬에서 `sops secrets/secrets.yaml`을 열고 다음 두 키를 실제 값으로 추가합니다.
   토큰은 채팅이나 Git 평문 파일에 붙여 넣지 않습니다.

   ```yaml
   telegram_bot_token: "BotFather가 발급한 토큰"
   telegram_chat_id: "본인과 봇의 개인 대화 숫자 ID"
   ```

   개인 대화 ID는 `python3 scripts/telegram-chat-id.py`로 조회합니다.
   토큰을 숨김 입력하면 봇의 `getUpdates` 응답에서 개인 대화 ID만 출력합니다.
   새 알림 전용 봇에서 사용하세요. 여러 ID가 표시되면 본인의 대화인지 확인해야 합니다.
   이 명령은 메시지를 전송하지 않습니다.

4. `modules/core/sops.nix`에서 `services.codexTelegram.enable = true;`로 변경합니다.
5. `git add .` 후 각 PC에서 `nh os switch` (`ns`)를 실행합니다.
   sops 비밀값 배포가 포함되므로 첫 적용에는 `hms`만 실행해서는 안 됩니다.
6. Codex CLI를 다시 시작하고 한 번 응답을 완료시켜 휴대폰 수신을 확인합니다.

각 PC에 기존 sops age 키가 있어야 합니다. 다른 PC에는 저장소 변경을 가져온 뒤 적용하세요.
Home Manager는 `~/.codex/config.toml`의 최상위 `notify`만 추가하고, 최초 변경 전
파일을 `config.toml.before-telegram`에 권한 0600으로 백업합니다. 기존의 다른 `notify`
훅이 있으면 덮어쓰지 않고 적용을 중단하므로 먼저 훅을 통합해야 합니다.
별도 `CODEX_HOME`을 사용하는 세션에는 해당 경로의 설정에 훅을 별도로 등록해야 합니다.

## 점검 및 해제

적용 뒤 아래 명령은 실제 테스트 메시지를 한 건 보냅니다.

```sh
~/.local/bin/codex-telegram-notify '{"type":"agent-turn-complete"}'
```

전송 실패 시 토큰을 포함하지 않는 오류를 stderr에 출력하고 10초 연결/읽기 타임아웃을
사용합니다. 중복 알림 방지를 위해 자동 재시도나 오프라인 큐는 사용하지 않습니다.
토큰과 대화 ID는 `/run/secrets/telegram_bot_token`, `/run/secrets/telegram_chat_id`에서 읽습니다.

해제하려면 공통 enable 값을 false로 바꾼 뒤 각 PC에 `ns`를 적용합니다.
이 모듈의 notify 항목만 제거되며 기존 터미널 알림 설정은 유지됩니다.

참고: [Codex notify](https://learn.chatgpt.com/docs/config-file/config-advanced#notifications),
[Telegram sendMessage](https://core.telegram.org/bots/api#sendmessage).
