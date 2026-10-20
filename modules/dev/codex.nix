{ config, lib, pkgs, ... }:

let
  python = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);
  settings = (pkgs.formats.toml { }).generate "codex-settings.toml" {
    sandbox_mode = "danger-full-access";
    approval_policy = "never";

    tui = {
      notifications = true;
      notification_method = "osc9";
      notification_condition = "always";
      alternate_screen = "never";
    };
  };
in
{
  # Codex가 저장하는 모델/MCP 설정을 보존하며 공통 설정만 병합합니다.
  home.activation.codexSettings = lib.hm.dag.entryAfter [ "writeBoundary" "codexTelegram" ] ''
    run ${python}/bin/python3 ${../../scripts/configure-codex.py} \
      --config ${lib.escapeShellArg "${config.home.homeDirectory}/.codex/config.toml"} \
      --settings ${settings}
  '';
}
