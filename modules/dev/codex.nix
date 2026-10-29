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

    ## Response Language and English Learning

    - Respond in English when I ask in English, and in Korean when I ask in Korean. Apply this to both progress updates and final responses.
    - For messages mixing Korean and English, use the language of the main question or request. Technical terms, code, commands, paths, logs, and quoted source material do not determine the response language.
    - Answer my request first, then place any English feedback at the very end of the final response so it is easy to find after long outputs.
    - When I ask in English, briefly correct my English only if there are meaningful grammar or expression issues. When I ask in Korean, do not add English feedback unless I explicitly request it.
    - Preserve my original technical intent and terminology.
    - Include my original sentence, the corrected sentence, and a brief explanation of its intended meaning in English, labeled Original, Corrected, and Meaning.
    - Explain at most one or two important corrections.
    - Do not rewrite sentences that are already clear and natural.
    - Distinguish grammatical errors from optional stylistic improvements.
    - Keep corrections concise and never let them interrupt the main development task.
    - Complete the requested development task normally before giving English feedback.
    - When English feedback applies to a mixed-language message, correct only the English prose. Do not treat code, commands, paths, logs, or quoted source material as my English writing.
    - Give feedback once per user message, without repeating it in every progress update.
  '';

  # Codex가 저장하는 모델/MCP 설정을 보존하며 공통 설정만 병합합니다.
  home.activation.codexSettings = lib.hm.dag.entryAfter [ "writeBoundary" "codexTelegram" ] ''
    run ${python}/bin/python3 ${../../scripts/configure-codex.py} \
      --config ${lib.escapeShellArg "${config.home.homeDirectory}/.codex/config.toml"} \
      --settings ${settings}
  '';
}
