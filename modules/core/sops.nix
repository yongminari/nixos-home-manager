{ config, inputs, pkgs, username, ... }:

let
  sopsPkgs = import inputs.sops-nix {
    pkgs = pkgs.extend (_final: prev: {
      buildGo125Module = prev.buildGo126Module;
    });
  };
in
{
  config = {
    sops = {
      # TODO(sops-nix, 2026-09-17): Keep this compatibility override until
      # upstream replaces buildGo125Module with a supported Go builder.
      # After updating sops-nix, remove this package override and the sopsPkgs
      # compatibility block only after `ns` succeeds without them.
      # https://github.com/Mic92/sops-nix/blob/master/pkgs/sops-install-secrets/default.nix
      package = sopsPkgs.sops-install-secrets;
      defaultSopsFile = ../../secrets/secrets.yaml;
      age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
      secrets = {
        gitlab_token = { owner = username; };
      };

      templates = {
        # GitLab CLI Configuration Template
        "glab-config.yml" = {
          owner = username;
          mode = "0600";
          content = ''
            hosts:
              192.168.0.230:
                token: ${config.sops.placeholder.gitlab_token}
                api_protocol: https
              git_protocol: ssh
          '';
        };
      };
    };
  };
}
