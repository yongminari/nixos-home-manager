{ config, lib, osConfig, pkgs, ... }:

let
  enabled = osConfig.services.codexTelegram.enable or false;
  command = "${config.home.homeDirectory}/.local/bin/codex-telegram-notify";
  python = pkgs.python3.withPackages (ps: [ ps.tomlkit ]);
  notifier = pkgs.writeShellScript "codex-telegram-notify" ''
    exec ${pkgs.python3}/bin/python3 ${../../scripts/codex-telegram-notify.py} \
      --host ${lib.escapeShellArg osConfig.networking.hostName} \
      --token-file ${lib.escapeShellArg osConfig.sops.secrets.telegram_bot_token.path} \
      --chat-id-file ${lib.escapeShellArg osConfig.sops.secrets.telegram_chat_id.path} "$@"
  '';
in
{
  home.file.".local/bin/codex-telegram-notify" = lib.mkIf enabled {
    source = notifier;
  };

  # Codex가 직접 수정하는 TOML은 그대로 유지하고 최상위 notify 키만 관리합니다.
  home.activation.codexTelegram = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${python}/bin/python3 ${../../scripts/configure-codex-telegram.py} \
      --config ${lib.escapeShellArg "${config.home.homeDirectory}/.codex/config.toml"} \
      --command ${lib.escapeShellArg command} ${lib.optionalString (!enabled) "--disable"}
  '';
}
