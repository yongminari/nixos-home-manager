{ config, lib, ... }:

{
  options.modules.core.vertexAI.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Google Vertex AI 설정 활성화 여부 (Credential 심볼릭 링크 및 환경 변수)";
  };

  config = {
    sops = {
      defaultSopsFile = ../../secrets/secrets.yaml;
      age.keyFile = "/home/yongminari/.config/sops/age/keys.txt";
      secrets = lib.mkIf config.modules.core.vertexAI.enable {
        vertex_ai_key = { owner = "yongminari"; }; # 기본 경로(/run/secrets/vertex_ai_key)에만 생성
      };
    };
  };
}
