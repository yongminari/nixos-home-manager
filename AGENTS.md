# Agent Project Instructions: nixos-home-manager

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
- **Repository Scope:** 이 저장소의 주 목적은 개인 PC 전체의 NixOS/Home Manager 관리입니다. 로컬 AI는 `ai-x1-pro`의 여러 호스트별 서비스 중 하나이며, 여기서는 GPU·Podman·systemd·방화벽·패키지·영속 저장 경로 등 시스템 설정만 담당합니다. 애플리케이션 코드·프롬프트·워크플로·테스트는 이 저장소의 범위가 아닙니다.
- **Hostname Awareness:** 작업을 시작하기 전에 항상 현재 `hostname`을 확인하여 어떤 기기에서 작업 중인지 파악하십시오.
- **NixOS Update Awareness:** 모든 호스트에서 매 작업 시작 시 `nixos-version`으로 현재 적용된 NixOS 버전을 확인하고, `flake.lock`의 `nixpkgs` 고정 리비전을 공식 `nixos-unstable` 채널의 최신 리비전과 읽기 전용으로 비교하십시오. 버전 번호 변경뿐 아니라 같은 버전 내 unstable 업데이트도 확인하며, 업데이트가 있으면 첫 진행 보고에 현재 버전과 업데이트 가능 여부를 명시하고 `nix flake update` 후 `ns` 및 `hms`로 적용하도록 안내하십시오. 잠금 파일만 갱신되고 시스템에 아직 적용되지 않은 경우도 구분하여 알리십시오. 확인에 실패하면 최신이라고 단정하지 말고 확인하지 못한 이유를 알리십시오. 이 검사는 알림 목적이며, 사용자가 업데이트를 요청하지 않았다면 잠금 파일 갱신이나 시스템 적용을 자동으로 실행하지 마십시오.
- **Scope Judgment:** 새로운 기능을 추가하거나 설정을 변경할 때, 이것이 모든 장비에 적용되어야 할 공통 기능(Horizontal)인지 특정 기기에만 특화된 기능(Host-specific)인지 먼저 판단하십시오.
- **Recommendation:** 판단 결과를 바탕으로 사용자에게 최적의 적용 방식을 먼저 추천하고, 최종 결정은 사용자가 할 수 있도록 하십시오.
- **Verification:** 작업을 완료한 후에는 항상 `hms` 또는 `ns`를 통해 설정을 검증할 것을 사용자에게 제안하거나, 직접 실행 가능한지 확인하십시오.
- **Package Addition:** 새로운 패키지 추가 시 `modules/dev/dev-tools.nix` 또는 관련 모듈에 적절히 분류하여 추가하십시오.
