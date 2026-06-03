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
          OLLAMA_BASE_URL = "http://localhost:4000"; # LiteLLM Proxy를 거치도록 설정
          WEBUI_AUTH = "False";
        };
        extraOptions = [ "--network=host" ];
      };
      
      # LiteLLM: Routing Proxy
      litellm = {
        image = "ghcr.io/berriai/litellm:main-latest";
        ports = [ "4000:4000" ];
        volumes = [
          "${./litellm_config.yaml}:/app/config.yaml"
        ];
        cmd = [ "--config" "/app/config.yaml" ];
        extraOptions = [ "--network=host" ]; # Ollama(localhost:11434)와 통신을 위해 필요
      };
    };
  };

  # persistence를 위해 디렉토리 생성 필요 (수동 또는 시스템 서비스로 처리)
  systemd.tmpfiles.rules = [
    "d /var/lib/ollama 0750 root root -"
  ];
}
