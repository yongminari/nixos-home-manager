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
  # 모든 호스트와 프로젝트에서 사용하는 Codex 전역 지침입니다.
  home.file.".codex/AGENTS.md".text = ''
    # Personal Codex instructions

    ## English learning

    - Whenever I write a message in English, begin your response with a corrected, natural version of my English, preserving my intended meaning.
    - Briefly explain one or two useful corrections so I can improve my English. Keep this feedback concise and supportive.
    - If my English is already natural and correct, say so briefly instead of inventing corrections.
    - Then answer my question or carry out my request as usual; English feedback must not replace the actual task.
    - For messages mixing Korean and English, correct only the English prose. Do not treat code, commands, paths, logs, or quoted source material as my English writing.
    - Give feedback once per user message, without repeating it in every progress update.
  '';

  # Codex가 저장하는 모델/MCP 설정을 보존하며 공통 설정만 병합합니다.
  home.activation.codexSettings = lib.hm.dag.entryAfter [ "writeBoundary" "codexTelegram" ] ''
    run ${python}/bin/python3 ${../../scripts/configure-codex.py} \
      --config ${lib.escapeShellArg "${config.home.homeDirectory}/.codex/config.toml"} \
      --settings ${settings}
  '';
}
