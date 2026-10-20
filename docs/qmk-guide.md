# ⌨️ QMK 사용 가이드 (NixOS)

이 문서는 NixOS 환경에서 스플릿 키보드의 펌웨어를 빌드하고 플래싱하는 방법을 정리한 가이드입니다.

---

## 🛠 1. 환경 준비 (이미 완료됨)

저장소는 QMK 펌웨어 작업을 위해 다음 설정을 제공합니다:
- **udev rules:** 키보드 인식 및 플래싱 권한 (`hardware.keyboard.qmk.enable = true`)
- **패키지:** `qmk` (CLI 빌드 도구)

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

## 💡 팁 & 트러블슈팅

### 권한 에러 (Permission Denied)
키보드가 인식되지 않거나 플래싱이 실패하면 `udev` 규칙이 제대로 로드되었는지 확인하세요.
```bash
# udev 규칙 수동 리로드 (필요시)
sudo udevadm control --reload-rules && sudo udevadm trigger
```

---

## 🔗 유용한 링크
- [QMK 공식 문서](https://docs.qmk.fm/)
- [QMK Configurator (웹 기반)](https://config.qmk.fm/)
