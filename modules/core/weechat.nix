{ config, pkgs, lib, ... }:

let
  # wee-slack 스크립트가 포함되도록 WeeChat 패키지를 재정의
  weechat-with-slack = pkgs.weechat.override {
    configure = { availablePlugins, ... }: {
      scripts = with pkgs.weechatScripts; [
        wee-slack
      ];
    };
  };

  # weechat 실행 시 sops로 암호화가 풀린 slack_token을 읽어서
  # wee-slack 설정에 동적으로 대입해주는 래퍼 스크립트 패키지
  weechat-wrapped = pkgs.writeShellScriptBin "weechat" ''
    if [ -f /run/secrets/slack_token ]; then
      SLACK_TOKEN=$(cat /run/secrets/slack_token)
      # wee-slack 플러그인의 토큰 설정값을 실행 시점에 설정하도록 전달
      exec ${weechat-with-slack}/bin/weechat -r "/set plugins.var.python.slack.slack_api_token $SLACK_TOKEN" "$@"
    else
      echo "Warning: /run/secrets/slack_token not found."
      echo "Starting weechat without automatic Slack login."
      exec ${weechat-with-slack}/bin/weechat "$@"
    fi
  '';
in
{
  # 래핑된 weechat 패키지(weechat 본체 + wee-slack 스크립트 포함)만 추가
  home.packages = [ weechat-wrapped ];
}
