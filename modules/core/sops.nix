{ config, username, ... }:

{
  imports = [ ../services/codex-telegram-secrets.nix ];

  config = {
    # 두 Telegram 비밀값을 등록한 뒤 true로 변경하면 모든 PC에서 활성화됩니다.
    services.codexTelegram.enable = false;

    sops = {
      defaultSopsFile = ../../secrets/secrets.yaml;
      age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
      secrets = {
        gitlab_token = { owner = username; };
        gitlab_personal_token = { owner = username; };
      };

      templates = {
        # GitLab CLI Configuration Template
        "glab-config.yml" = {
          owner = username;
          mode = "0600";
          content = ''
            git_protocol: ssh
            hosts:
              192.168.0.230:
                token: ${config.sops.placeholder.gitlab_token}
                api_protocol: https
              gitlab.com:
                token: ${config.sops.placeholder.gitlab_personal_token}
                api_protocol: https
          '';
        };
      };
    };
  };
}
