{ config, pkgs, ... }:

{
  # --- [1. GPU Acceleration (AMD ROCm)] ---
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
    ];
  };

  # --- [2. LLM Infrastructure (Podman)] ---
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      # Ollama: LLM Engine with ROCm acceleration
      ollama = {
        image = "ollama/ollama:rocm";
        volumes = [ "/var/lib/ollama:/root/.ollama" ];
        environment = {
          OLLAMA_NUM_PARALLEL = "4";     # 4개 세션 동시 처리
          OLLAMA_MAX_LOADED_MODELS = "3"; # 3개 모델 상시 로드 (E4B, 26B, 31B)
        };
        extraOptions = [
          "--device=/dev/kfd"            # AMD Compute device
          "--device=/dev/dri"            # AMD Render device
          "--memory=80g"                 # 최대 80GB 메모리 사용 제한
          "--shm-size=16g"               # 공유 메모리 확보
        ];
      };

      # Open WebUI: Frontend
      open-webui = {
        image = "ghcr.io/open-webui/open-webui:main";
        ports = [ "3000:8080" ];
        environment = {
          OLLAMA_BASE_URL = "http://localhost:11434";
          WEBUI_AUTH = "False"; # 로컬용이므로 인증 비활성화 (선택 사항)
        };
        extraOptions = [ "--network=host" ]; # Ollama와 직접 통신을 위해 호스트 네트워크 사용
      };
      
      # LiteLLM: Routing Proxy (나이도별 라우팅을 위해 추후 설정 확장 가능)
      litellm = {
        image = "ghcr.io/berriai/litellm:main-latest";
        ports = [ "4000:4000" ];
        # config 파일은 추후 sops나 별도 파일을 통해 마운트 권장
        # command = [ "--config", "/app/config.yaml" ];
      };
    };
  };

  # persistence를 위해 디렉토리 생성 필요 (수동 또는 시스템 서비스로 처리)
  systemd.tmpfiles.rules = [
    "d /var/lib/ollama 0750 root root -"
  ];
}
