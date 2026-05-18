{ config, ... }:

{
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/home/yongminari/.config/sops/age/keys.txt";
    secrets = {
      vertex_ai_key = {
        path = "/home/yongminari/.config/gcloud/application_default_credentials.json";
        owner = "yongminari";
      };
    };
  };
}
