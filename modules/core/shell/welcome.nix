{ config, pkgs, lib, ... }:

let
  welcomeScript = pkgs.writeShellScriptBin "welcome-msg" ''
    LOLCAT="${pkgs.lolcat}/bin/lolcat"

    # 현재 실제 작동 중인 쉘 이름을 가져오는 가장 확실한 방법
    # 스크립트를 실행한 부모 프로세스(쉘)의 이름을 찾습니다.
    current_shell=$(ps -p $PPID -o comm= | sed 's/^-//')

    if [[ -n "$ZELLIJ" ]] || [[ -n "$SSH_CLIENT" ]]; then
      printf "\e[?7l"
      
      os_name="Linux"
      [[ -f /etc/os-release ]] && os_name=$(grep PRETTY_NAME /etc/os-release | cut -d '"' -f2)

      {
        session_type=$([[ -n "$ZELLIJ" ]] && echo "Zellij" || echo "Remote SSH")
        host_name=$(uname -n)
        kernel_info=$(uname -r)
        current_date=$(date +'%Y-%m-%d %H:%M:%S')
        current_user=$(whoami)

        echo   " ╭────────────────────────────────────────────────────────────────────╮"
        printf " │  ███                  %-44s │\n" "$os_name"
        printf " │ ░░░███                %-44s │\n" ""
        printf " │   ░░░███              HOST      : %-32s │\n" "$host_name"
        printf " │     ░░░███            SESSION   : %-32s │\n" "$session_type"
        printf " │      ███░             Shell     : %-32s │\n" "$current_shell"
        printf " │    ███░               Kernel    : %-32s │\n" "$kernel_info"
        printf " │  ███░      █████████  Date      : %-32s │\n" "$current_date"
        printf " │ ░░░       ░░░░░░░░░   Who       : %-32s │\n" "$current_user"
        echo   " ╰────────────────────────────────────────────────────────────────────╯"
      } | $LOLCAT

      echo -e "\nWelcome back to \x1b[94mShell\x1b[0m, \x1b[1m$USER!\x1b[0m"
      printf "\e[?7h"
    fi
  '';
in
{
  home.packages = [ welcomeScript pkgs.lolcat ];
}
