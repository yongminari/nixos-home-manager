{ config, pkgs, lib, ... }:

let
  # Powerline 반원 문자로 한 줄 높이의 둥근 캡슐을 만듭니다.
  capsule = colors: background: foreground: text:
    "#[fg=${background},bg=${colors.bg}]#[fg=${foreground},bg=${background},bold] ${text} #[fg=${background},bg=${colors.bg}]";

  mkZellijConfig = themeName: colors: ''
    theme "${themeName}"
    // 시스템 기본쉘(Bash)을 무시하고 Zsh를 강제로 사용하도록 설정
    default_shell "${pkgs.zsh}/bin/zsh"
    default_layout "default"
    pane_frames true
    simplified_ui false
    mirror_session_to_terminal_title true
    mouse_mode true
    copy_on_select true

    // 기본/스왑 레이아웃의 상단 바만 교체하고 하단 단축키 안내는 유지합니다.
    plugins {
      tab-bar location="file:${pkgs.zellijPlugins.zjstatus}" {
        format_left "#[bg=${colors.bg}] ${capsule colors colors.accent colors.bg "{session}"} "
        format_center "{tabs}"
        format_right "{datetime}#[bg=${colors.bg}] "
        format_space "#[bg=${colors.bg}]"
        format_hide_on_overlength "true"
        format_precedence "rcl"

        tab_normal "${capsule colors colors.surface colors.fg "{index} · {name}"}#[bg=${colors.bg}] "
        tab_active "${capsule colors colors.highlight colors.bg "{index} · {name}"}#[bg=${colors.bg}] "

        datetime "${capsule colors colors.highlight colors.bg "{format}"}"
        datetime_format "%m/%d · %H:%M"
        datetime_timezone "Asia/Seoul"

        border_enabled "false"
        hide_frame_for_single_pane "false"
      }
    }

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
  
  xdg.configFile."zellij/config.kdl".text = mkZellijConfig "ayu_dark" {
    # 상단 바: Nord
    bg = "#2e3440";
    fg = "#d8dee9";
    accent = "#88c0d0";
    surface = "#3b4252";
    highlight = "#8fbcbb";
  };
  xdg.configFile."zellij/remote.kdl".text = mkZellijConfig "iceberg-light" {
    # 상단 바: Catppuccin Mocha
    bg = "#1e1e2e";
    fg = "#cdd6f4";
    accent = "#cba6f7";
    surface = "#313244";
    highlight = "#89b4fa";
  };
}
