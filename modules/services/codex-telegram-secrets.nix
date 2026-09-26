{ config, lib, username, ... }:

{
  options.services.codexTelegram.enable = lib.mkEnableOption "Codex Telegram completion notifications";

  config = lib.mkIf config.services.codexTelegram.enable {
    sops.secrets = {
      telegram_bot_token = { owner = username; mode = "0400"; };
      telegram_chat_id = { owner = username; mode = "0400"; };
    };
  };
}
