{ config, pkgs, lib, ... }:

{
  programs.nushell = {
    enable = true;
    
    envFile.text = ''
      let nix_bin = ($env.HOME | path join ".nix-profile" "bin")
      let hm_bin = ($env.HOME | path join ".local" "state" "nix" "profiles" "home-manager" "profile" "bin")
      
      $env.PATH = (
        $env.PATH 
        | split row (char esep) 
        | prepend "/nix/var/nix/profiles/default/bin"
        | prepend "/run/current-system/sw/bin"
        | prepend $nix_bin
        | prepend $hm_bin
        | uniq
      )

      # [Gemini CLI Settings]
      $env.GOOGLE_CLOUD_PROJECT = "gemini-cli-vertex-ai-493207"
      $env.GOOGLE_CLOUD_LOCATION = "global"
      $env.GOOGLE_APPLICATION_CREDENTIALS = "/home/yongminari/.config/gcloud/application_default_credentials.json"
      $env.GOOGLE_GENAI_USE_VERTEXAI = "True"
    '';

    configFile.text = ''
      $env.config = {
        show_banner: false
        edit_mode: vi
      }
      # welcome-msg 호출 (nushell 방식)
      ^welcome-msg
    '';

    shellAliases = {
      la = "ls -a";
      ll = "ls -a";
      g  = "git";
      v  = "nvim";
    };
  };
}
