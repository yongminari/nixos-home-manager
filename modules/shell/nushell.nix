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

      # [Environment Detection]
      let is_ssh = (not ($env | get -o SSH_CLIENT | is-empty)) or (not ($env | get -o SSH_TTY | is-empty)) or (not ($env | get -o SSH_CONNECTION | is-empty))
      let is_docker = ("/.dockerenv" | path exists) or (if ("/proc/1/cgroup" | path exists) { (open /proc/1/cgroup | str contains "docker") } else { false })

      # [Starship 설정 연동]
      if ($is_ssh) {
        $env.STARSHIP_CONFIG = ($env.HOME | path join ".config" "starship-ssh.toml")
      } else if ($is_docker) {
        $env.STARSHIP_CONFIG = ($env.HOME | path join ".config" "starship-docker.toml")
      }
    '';

    configFile.text = ''
      $env.config = {
        show_banner: false
        edit_mode: vi
      }
      # welcome-msg 호출 (nushell 방식)
      ^welcome-msg

      # [Zellij Wrapper]
      let is_ssh = (not ($env | get -o SSH_CLIENT | is-empty)) or (not ($env | get -o SSH_TTY | is-empty)) or (not ($env | get -o SSH_CONNECTION | is-empty))
      let is_docker = ("/.dockerenv" | path exists) or (if ("/proc/1/cgroup" | path exists) { (open /proc/1/cgroup | str contains "docker") } else { false })
      
      if ($is_ssh or $is_docker) {
        alias zellij = zellij --config ($env.HOME | path join ".config" "zellij" "remote.kdl")
      }
    '';

    shellAliases = {
      la = "ls -a";
      ll = "ls -a";
      g  = "git";
      v  = "nvim";
    };

    extraConfig = ''
      # [SSH Wrapper]
      # Ghostty 사용 시 'ghostty +ssh'를 통해 terminfo 자동 주입 시도
      def --env ssh [...args] {
        let is_ghostty = ($env.TERM? == "xterm-ghostty") or ($env.TERM_PROGRAM? == "Ghostty")
        if $is_ghostty {
          ^ghostty +ssh ...$args
        } else {
          with-env { TERM: "xterm-256color", COLORTERM: "truecolor" } {
            ^ssh ...$args
          }
        }
      }
    '';
  };
}
