{ config, pkgs, lib, ... }:

let
  mkZellijConfig = lockKey: themeName: ''
    theme "${themeName}"
    // 시스템 기본쉘(Bash)을 무시하고 Zsh를 강제로 사용하도록 설정
    default_shell "${pkgs.zsh}/bin/zsh"
    default_layout "default"
    pane_frames true
    simplified_ui false
    mirror_session_to_terminal_title true
    mouse_mode true
    copy_on_select true

    keybinds {
      shared_except "locked" {
        ${if lockKey == "Ctrl g" then "" else "unbind \"Ctrl g\""}
        bind "${lockKey}" { SwitchToMode "Locked"; }
        bind "Alt h" { MoveFocusOrTab "Left"; }
        bind "Alt l" { MoveFocusOrTab "Right"; }
        bind "Alt j" { MoveFocus "Down"; }
        bind "Alt k" { MoveFocus "Up"; }
        bind "Alt =" { Resize "Increase"; }
        bind "Alt -" { Resize "Decrease"; }
        bind "Alt n" { NewPane "Right"; }
        bind "Alt i" { MoveTab "Left"; }
        bind "Alt o" { MoveTab "Right"; }
        bind "Ctrl x" { CloseFocus; SwitchToMode "Normal"; }
      }
      locked {
        ${if lockKey == "Ctrl g" then "" else "unbind \"Ctrl g\""}
        bind "${lockKey}" { SwitchToMode "Normal"; }
      }
    }
  '';
in
{
  programs.zellij = {
    enable = true;
    enableZshIntegration = false;
    enableBashIntegration = false;
  };
  
  xdg.configFile."zellij/config.kdl".text = mkZellijConfig "Ctrl g" "ayu_dark";
  xdg.configFile."zellij/remote.kdl".text = mkZellijConfig "Ctrl a" "iceberg-light";
}
