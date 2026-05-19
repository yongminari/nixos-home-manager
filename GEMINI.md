# Gemini Project Instructions: nixos-home-manager

이 프로젝트는 NixOS와 Home Manager를 Flake 기반으로 통합 관리하는 시스템 설정 저장소입니다.

## 🛠 Core Architecture
- **OS/Package Manager:** NixOS (Unstable channel) + Home Manager.
- **Flake Structure:** `flake.nix`가 전체 시스템(`nixosConfigurations`)과 유저 설정(`homeConfigurations`)의 엔트리포인트입니다.
- **Modularization:** 모든 설정은 `modules/` 디렉토리에 기능별로 분리되어 있으며, `home.nix`나 `configuration.nix`에서 임포트합니다.

## 🚀 Key Workflows & Commands
- **nh (Nix Helper) 사용:** 시스템 빌드와 적용에 `nh`를 우선적으로 사용합니다.
- **Aliases:**
  - `hms`: `nh home switch` (Home Manager 설정 적용)
  - `ns`: `nh os switch` (Nixos 시스템 설정 적용)
- **Git & Flake:** 설정을 변경한 후에는 반드시 `git add .`를 수행해야 Nix Flake가 새로운 파일을 인식할 수 있습니다.

## 📝 Conventions
- **Surgical Updates:** 코드 수정 시 기존 스타일과 구조를 엄격히 준수합니다.
- **Secret Management:** 민감한 정보는 직접 노출하지 않고 `sops-nix`를 통해 관리합니다 (`secrets/secrets.yaml`).
- **Niri Config:** 창 관리자 설정은 `modules/desktop/niri/` 하위의 KDL 파일들을 사용합니다.

## 🤖 Agent Role
- **Hostname Awareness:** 작업을 시작하기 전에 항상 현재 `hostname`을 확인하여 어떤 기기에서 작업 중인지 파악하십시오.
- **Scope Judgment:** 새로운 기능을 추가하거나 설정을 변경할 때, 이것이 모든 장비에 적용되어야 할 공통 기능(Horizontal)인지 특정 기기에만 특화된 기능(Host-specific)인지 먼저 판단하십시오.
- **Recommendation:** 판단 결과를 바탕으로 사용자에게 최적의 적용 방식을 먼저 추천하고, 최종 결정은 사용자가 할 수 있도록 하십시오.
- **Verification:** 작업을 완료한 후에는 항상 `hms` 또는 `ns`를 통해 설정을 검증할 것을 사용자에게 제안하거나, 직접 실행 가능한지 확인하십시오.
- **Package Addition:** 새로운 패키지 추가 시 `modules/dev/dev-tools.nix` 또는 관련 모듈에 적절히 분류하여 추가하십시오.
