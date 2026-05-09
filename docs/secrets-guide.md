# 🔐 비밀 관리 및 WireGuard 가이드

이 프로젝트는 `sops-nix`를 사용하여 민감한 정보(API 키, VPN 비밀키 등)를 안전하게 관리합니다.

## 1. 비밀 관리 (sops-nix)

### 🔑 Age 키 관리 (가장 중요!)
암호화된 파일을 풀기 위한 마스터 키입니다.
*   **경로**: `~/.config/sops/age/keys.txt`
*   **백업**: PC 포맷에 대비하여 이 파일의 내용을 **Bitwarden**이나 **구글 클라우드(비번 압축)** 등 안전한 곳에 텍스트로 보관하세요.
*   **복구**: 새 환경에서 위 경로에 폴더를 만들고 백업한 내용을 `keys.txt` 파일로 저장하면 즉시 모든 암호가 풀립니다.

### 📝 비밀 수정하기
비밀번호나 키를 변경해야 할 때:
```bash
# sops를 통해 파일을 열고 수정 (저장 시 자동 암호화)
nix-shell -p sops --run "sops secrets/secrets.yaml"
```

### 📦 암호화된 파일 추가
새로운 비밀 정보를 추가할 때는 `secrets/secrets.yaml`에 키-값 쌍을 넣고 아래 명령어로 암호화 상태를 유지하세요.
```bash
nix-shell -p sops --run "sops -e -i secrets/secrets.yaml"
```

---

## 🌐 WireGuard (VPN) 제어

기존의 자동 접속 방식에서 **수동 토글 방식**으로 변경되었습니다.

### 터미널 명령어 (Alias)
편리한 사용을 위해 다음 단축 명령어가 등록되어 있습니다:
*   `vpn-on`: VPN 연결 시작 (`wg-quick up wg0`)
*   `vpn-off`: VPN 연결 해제 (`wg-quick down wg0`)
*   `vpn-stat`: 현재 VPN 연결 상태 및 트래픽 확인 (`wg`)

### 설정 특징
*   **부팅 시 자동 시작 방지**: `autostart = false` 설정으로 부팅 시에는 꺼져 있습니다.
*   **보안**: 모든 비밀키와 PSK는 `sops`를 통해 암호화되어 관리됩니다.

---

## 💡 유용한 팁

### 보안 압축 백업 (nix-shell 활용)
`age` 키 파일을 암호 걸어 압축하여 클라우드에 올리고 싶을 때, 따로 프로그램을 설치하지 않고 아래 명령어로 즉시 수행할 수 있습니다:
```bash
# keys.txt를 암호를 걸어 my_keys.7z로 압축
nix-shell -p p7zip --run "7z a -p my_keys.7z ~/.config/sops/age/keys.txt"
```

### 암호화 상태 확인
파일이 제대로 암호화되어 깃허브에 올려도 되는 상태인지 확인하려면:
```bash
cat secrets/secrets.yaml
```
`ENC[AES256_GCM,...]` 같은 문구가 보이면 성공입니다.
