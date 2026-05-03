{ config, pkgs, lib, ... }:

{
  programs.nushell = {
    enable = true;
    
    # [Nushell Settings] - 퍼지 검색 및 고도화된 완성 설정
    settings = {
      show_banner = false;
      edit_mode = "vi";
      completions = {
        case_sensitive = false;
        quick = true;
        partial = true;
        algorithm = "fuzzy"; # 퍼지 검색 활성화
        external = { 
          enable = true; 
          max_results = 100; 
        };
      };
    };

    envFile.text = ''
      # [Nix & Home Manager Path Setup]
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
      let is_ssh = (not ($env | get -o SSH_CLIENT | is-empty)) or (not ($env | get -o SSH_TTY | is-empty))
      let is_docker = ("/.dockerenv" | path exists)

      # [Starship 설정 연동]
      if ($is_ssh) {
        $env.STARSHIP_CONFIG = ($env.HOME | path join ".config" "starship-ssh.toml")
      } else if ($is_docker) {
        $env.STARSHIP_CONFIG = ($env.HOME | path join ".config" "starship-docker.toml")
      }
    '';

    extraConfig = ''
      # [Carapace Completion Helper]
      # 모든 명령어에 대해 강력한 자동완성 지원
      let carapace_completer = { |spans| carapace $spans.0 nushell ...$spans | from json }
      $env.config.completions.external.completer = $carapace_completer

      # [Welcome Message]
      ^welcome-msg

      # [Environment Check for Aliases]
      let is_ssh = (not ($env | get -o SSH_CLIENT | is-empty)) or (not ($env | get -o SSH_TTY | is-empty))
      let is_docker = ("/.dockerenv" | path exists)

      # [SSH Wrapper]
      def --env ssh [...args] {
        let is_ghostty = ($env.TERM? == "xterm-ghostty") or ($env.TERM_PROGRAM? == "Ghostty")
        if ($is_ghostty and ($args | length) > 0) {
          ^ghostty +ssh ...$args
        } else {
          with-env { TERM: "xterm-256color", COLORTERM: "truecolor" } {
            ^ssh ...$args
          }
        }
      }

      # [Zellij Wrapper]
      if ($is_ssh or $is_docker) {
        alias zellij = zellij --config ($env.HOME | path join ".config" "zellij" "remote.kdl")
      }

      # [Dynamic Aliases for Nushell]
      let has_eza = (which eza | is-empty | not $in)
      
      if $has_eza {
        alias ls = eza --icons
        alias ll = eza -l --icons --git -a
        alias lt = eza --tree --level=2 --icons --git
      } else {
        alias ll = ls -a
      }

      if (which bat | is-empty | not $in) {
        alias cat = bat
      }
    '';

    shellAliases = {
      g  = "git";
      v  = "nvim";
    };
  };
}
