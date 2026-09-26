{ config, pkgs, lib, ... }:

let
  mkZellijConfig = themeName: ''
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
        bind "Ctrl g" { SwitchToMode "Locked"; }
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
        bind "Ctrl g" { SwitchToMode "Normal"; }
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
  
  xdg.configFile."zellij/config.kdl".text = mkZellijConfig "ayu_dark";
  xdg.configFile."zellij/remote.kdl".text = mkZellijConfig "iceberg-light";
}
