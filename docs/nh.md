# 🚀 nh (Nix Helper) Usage Guide

`nh`는 `nixos-rebuild`와 `home-manager` 명령어를 더 직관적이고 시각적으로 사용하기 위한 도구입니다.

## 🛠️ Key Commands

### 1. 시스템 및 유저 설정 적용 (Switch)
기존의 `sudo nixos-rebuild switch`와 `home-manager switch`를 대체합니다.

```bash
# 현재 호스트의 시스템 + 유저 설정 통합 업데이트
nh os switch

# (선택 사항) 특정 호스트 명시 시
nh os switch --hostname <hostname>

# 유저 설정(Home Manager)만 업데이트 시
nh home switch
```

- **장점**: 
    - 빌드 과정을 `nix-output-monitor`를 통해 그래프로 보여줍니다.
    - 설정 파일에서 `flake` 경로를 `/home/yongminari/nixos-home-manager`로 고정해두었기 때문에, 어느 디렉토리에서든 실행 가능합니다.

### 2. 패키지 검색 (Search)
`nix search`보다 훨씬 빠르고 깔끔한 결과를 보여줍니다.

```bash
nh search <package-name>
```

### 3. 시스템 청소 (Clean)
오래된 빌드 세대(Generations)를 삭제하여 디스크 용량을 확보합니다.

```bash
# 4일 이상 지났거나 최신 3개 이외의 세대 삭제
nh clean all
```
*설정에 따라 자동으로 실행되도록 구성되어 있습니다.*

---

## 💡 Troubleshooting

### "Hostname not found" 에러 발생 시
현재 기기의 `hostname`이 `flake.nix`에 정의된 이름(`galaxy-book` 또는 `ai-x1-pro`)과 일치하는지 확인하세요. 만약 다르다면 다음과 같이 실행합니다:

```bash
nh os switch --hostname galaxy-book
```
