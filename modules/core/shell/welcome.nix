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

  hyprCheatScript = pkgs.writeShellScriptBin "hypr-cheat" ''
    printf "\n  \033[1;35m🪄 [Hyprland Core & Launch]\033[0m\n"
    printf "  \033[1;32mSuper + Enter\033[0m       Launch Ghostty\n"
    printf "  \033[1;32mSuper + Space\033[0m       Launch Noctalia (Apps)\n"
    printf "  \033[1;32mSuper + Q\033[0m           Kill Active Window\n"
    printf "  \033[1;32mSuper + F\033[0m           Toggle Fullscreen\n"
    printf "  \033[1;32mSuper + V\033[0m           Toggle Floating\n\n"

    printf "  \033[1;35m🪟 [Window Control]\033[0m\n"
    printf "  \033[1;32mSuper + h/j/k/l\033[0m     Move Focus (Vim Style)\n"
    printf "  \033[1;32mSuper + , / .\033[0m       Focus Monitor (Left/Right)\n"
    printf "  \033[1;32mSuper + Shift + hjkl\033[0m Move Window Position\n"
    printf "  \033[1;32mSuper + Shift + , / .\033[0m Move Window to Monitor\n"
    printf "  \033[1;32mSuper + 1~0\033[0m         Switch Workspace\n"
    printf "  \033[1;32mSuper + Shift + 1~0\033[0m Move Window to Workspace\n\n"

    printf "  \033[1;35m📸 [Utilities & System]\033[0m\n"
    printf "  \033[1;32mPrint (PrtSc)\033[0m       Screenshot (Full)\n"
    printf "  \033[1;32mSuper + Shift + S\033[0m   Screenshot (Area + Editor)\n"
    printf "  \033[1;32mSuper + Escape\033[0m      Lock Screen (Hyprlock)\n"
    printf "  \033[1;32mSuper + Shift + E\033[0m   Exit Hyprland (Logout)\n\n" | ${pkgs.lolcat}/bin/lolcat
  '';

  niriCheatScript = pkgs.writeShellScriptBin "niri-cheat" ''
    printf "\n  \033[1;35m🪄 [Niri Core & Launch]\033[0m\n"
    printf "  \033[1;32mSuper + Enter\033[0m       Launch Ghostty\n"
    printf "  \033[1;32mSuper + Space\033[0m       Launch Application Menu\n"
    printf "  \033[1;32mSuper + Q\033[0m           Close Window\n"
    printf "  \033[1;32mSuper + F\033[0m           Toggle Fullscreen\n\n"

    printf "  \033[1;35m🪟 [Layout & Navigation]\033[0m\n"
    printf "  \033[1;32mSuper + h/j/k/l\033[0m     Move Focus (Vim Style)\n"
    printf "  \033[1;32mSuper + Shift + hjkl\033[0m Move Window\n"
    printf "  \033[1;32mSuper + [ / ]\033[0m       Change Window Width\n"
    printf "  \033[1;32mSuper + R\033[0m           Switch to Preset Width\n"
    printf "  \033[1;32mSuper + 1~9\033[0m         Go to Workspace\n\n"

    printf "  \033[1;35m📸 [Utilities]\033[0m\n"
    printf "  \033[1;32mPrint\033[0m               Full Screenshot\n"
    printf "  \033[1;32mSuper + Shift + S\033[0m   Area Screenshot\n"
    printf "  \033[1;32mSuper + Shift + Q\033[0m   Quit Niri\n\n" | ${pkgs.lolcat}/bin/lolcat
  '';

  yaziCheatScript = pkgs.writeShellScriptBin "yazi-cheat" ''
    printf "\n  \033[1;34m📂 [Navigation]\033[0m\n  \033[1;32mh / j / k / l\033[0m       Left / Down / Up / Right\n  \033[1;32mg g / G\033[0m             Top / Bottom\n  \033[1;32mEnter / Backspace\033[0m   Enter / Leave directory\n  \033[1;32mz\033[0m                   Jump (zoxide integration)\n\n  \033[1;34m🛠️ [Operations]\033[0m\n  \033[1;32my / x / p\033[0m           Copy / Cut / Paste\n  \033[1;32md\033[0m                   Delete (Trash)\n  \033[1;32mr\033[0m                   Rename\n  \033[1;32ma\033[0m                   Create new file\n  \033[1;32m.\033[0m                   Toggle hidden files\n\n  \033[1;34m🔍 [Selection & Search]\033[0m\n  \033[1;32mv\033[0m                   Visual selection mode\n  \033[1;32mSpace\033[0m               Toggle selection\n  \033[1;32mf\033[0m                   Filter (Search) files\n  \033[1;32m/\033[0m                   Find within results\n\n  \033[1;34m🚪 [Exit]\033[0m\n  \033[1;32mq\033[0m                   Quit Yazi\n  \033[1;32mQ\033[0m                   Quit and keep current directory\n\n" | ${pkgs.lolcat}/bin/lolcat
  '';
in
{
  home.packages = [ 
    welcomeScript 
    hyprCheatScript
    niriCheatScript
    yaziCheatScript
    pkgs.lolcat 
  ];
}
