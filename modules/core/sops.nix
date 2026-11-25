{ config, username, ... }:

{
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
              skip_tls_verify: true
            gitlab.com:
              token: ${config.sops.placeholder.gitlab_personal_token}
              api_protocol: https
        '';
      };
    };
  };
}
