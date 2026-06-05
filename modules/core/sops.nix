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
      secrets = {
        gitlab_token = { owner = "yongminari"; };
      } // (if config.modules.core.vertexAI.enable then {
        vertex_ai_key = { owner = "yongminari"; };
      } else {});

      templates = {
        # GitLab CLI Configuration Template
        "glab-config.yml" = {
          owner = "yongminari";
          mode = "0600";
          content = ''
            hosts:
              192.168.0.230:
                token: ${config.sops.placeholder.gitlab_token}
                api_protocol: https
                git_protocol: ssh
          '';
        };

        # Vertex AI Credentials JSON Template Migration
        "application_default_credentials.json" = lib.mkIf config.modules.core.vertexAI.enable {
          owner = "yongminari";
          content = ''
            ${config.sops.placeholder.vertex_ai_key}
          '';
        };
      };
    };
  };
}
