# ⌨️ QMK & Vial 사용 가이드 (NixOS)

이 문서는 NixOS 환경에서 스플릿 키보드의 펌웨어를 빌드, 플래싱 및 실시간 설정하는 방법을 정리한 가이드입니다.

---

## 🛠 1. 환경 준비 (이미 완료됨)

현재 시스템에는 다음 설정이 적용되어 있습니다:
- **udev rules:** 키보드 인식 및 플래싱 권한 (`hardware.keyboard.qmk.enable = true`)
- **패키지:** `qmk` (CLI 빌드 도구), `vial` (GUI 설정 도구)

---

## 🚀 2. QMK (CLI 기반 펌웨어 빌드)

QMK는 코드를 수정하여 키보드에 직접 펌웨어를 올리는 방식입니다.

### 초기 설정 (최초 1회)
```bash
qmk setup
# ~/.qmk_firmware 디렉토리에 소스가 저장됩니다.
```

### 펌웨어 빌드
자신의 키보드 모델(`-kb`)과 키맵 이름(`-km`)을 지정합니다.
```bash
# 예시: Corne(crkbd) 키보드 빌드
qmk compile -kb crkbd/rev1 -km default
```

### 펌웨어 플래싱 (키보드에 굽기)
빌드와 동시에 키보드에 펌웨어를 전송합니다. 키보드의 **Reset 버튼**을 누르라는 메시지가 뜰 때 버튼을 누르면 시작됩니다.
```bash
qmk flash -kb crkbd/rev1 -km default
```

---

## 🖱 3. Vial (GUI 기반 실시간 설정)

Vial은 펌웨어를 새로 굽지 않고도 GUI에서 즉시 키 매핑을 바꿀 수 있는 도구입니다.

### 실행 방법
터미널이나 앱 런처에서 실행합니다.
```bash
vial
```

### 주요 기능
1.  **Matrix View:** 현재 설정된 키 레이아웃을 시각적으로 확인하고 마우스 클릭으로 변경.
2.  **Layers:** 레이어별 키 할당 (최대 16~32개).
3.  **Macros:** 복잡한 단축키나 문자열을 매크로로 저장.
4.  **Encoder:** 노브(Encoder)가 있는 경우 회전 시 동작 설정.
5.  **Lighting:** RGB LED 효과 및 색상 실시간 조절.

---

## 💡 팁 & 트러블슈팅

### 1. Vial 지원 여부 확인
모든 QMK 키보드가 Vial을 지원하는 것은 아닙니다. 펌웨어 빌드 시 Vial 전용 소스를 사용했는지 확인하세요.

### 2. 권한 에러 (Permission Denied)
키보드가 인식되지 않거나 플래싱이 실패하면 `udev` 규칙이 제대로 로드되었는지 확인하세요.
```bash
# udev 규칙 수동 리로드 (필요시)
sudo udevadm control --reload-rules && sudo udevadm trigger
```

### 3. Kanata와의 충돌
QMK/Vial에서 강력한 레이어 기능을 사용한다면, OS 수준의 Kanata 설정과 키가 겹쳐서 혼란을 줄 수 있습니다. 새 키보드에 적응할 때는 **Kanata를 잠시 끄는 것(Raw Mode)**을 추천합니다.

---

## 🔗 유용한 링크
- [QMK 공식 문서](https://docs.qmk.fm/)
- [Vial 공식 사이트](https://get.vial.today/)
- [QMK Configurator (웹 기반)](https://config.qmk.fm/)
