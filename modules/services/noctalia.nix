{ inputs, pkgs, lib, config, ... }:

let
  lFramePreset = builtins.fromTOML (builtins.readFile ./noctalia/l-frame.toml);

  # 시각과 날짜를 별도의 기본 시계로 배치해 긴 날짜가 시간 숫자를 줄이지 않게 합니다.
  lockWidgets = lib.concatMapAttrs (name: display:
    let
      clock = format: y: width: height: {
        type = "clock";
        output = display.output;
        placement_width = display.width;
        placement_height = display.height;
        cx = display.width * 0.5;
        cy = display.height * y;
        box_width = display.width * width;
        box_height = display.height * height;
        settings = { inherit format; clock_style = "digital"; center_text = true; };
      };
    in {
      "time_${name}" = clock "{:%H:%M:%S}" 0.36 0.90 0.44;
      "date_${name}" = clock "{:%Y-%m-%d}" 0.66 0.68 0.14;
    }
  ) config.local.desktop.lockDisplays;

  migrateLockWidgets = pkgs.writeShellScript "migrate-noctalia-lock-widgets" ''
    exec ${pkgs.python3.withPackages (p: [ p.tomlkit ])}/bin/python3 ${./noctalia/migrate-lock-widgets.py} ${lib.escapeShellArgs (builtins.attrNames lockWidgets)}
  '';

  wallpaperSync = pkgs.writeShellApplication {
    name = "noctalia-wallpaper-sync";
    runtimeInputs = [ pkgs.niri config.programs.noctalia.package pkgs.python3 ];
    text = ''
      exec python3 ${./noctalia-wallpaper-sync.py}
    '';
  };

  fetchWallhaven = pkgs.writeShellScriptBin "fetch-wallhaven" ''
    set -u

    WALLPAPER_DIR="$HOME/Pictures/Wallpapers/Black"
    STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/fetch-wallhaven"
    HISTORY_FILE="$STATE_DIR/seen-ids"
    APPLIED_FILE="$STATE_DIR/applied-ids"
    DOWNLOAD_FILE="$STATE_DIR/candidate.download"
    API_URL="https://wallhaven.cc/api/v1/search?purity=100&sorting=random"
    # 어두운 밤하늘·우주 사진 또는 여성 인물 키워드를 포함하는 K-pop 사진을 검색합니다.
    SEARCH_TOPICS=(space k-pop)
    SPACE_KEYWORDS=("night sky" "Milky Way" space galaxy nebula)
    PEOPLE_KEYWORDS=(girl women "korean women" "korean girl")
    MAX_MEAN_LUMINANCE="0.28"
    MAX_ATTEMPTS=5

    mkdir -p "$WALLPAPER_DIR" "$STATE_DIR"
    # 타이머와 수동 단축키가 동시에 실행되어 같은 이미지를 처리하지 않도록 합니다.
    exec 9>"$STATE_DIR/lock"
    if ! ${pkgs.util-linux}/bin/flock -n 9; then
      echo "A wallpaper fetch is already running; keeping the current wallpaper." >&2
      exit 0
    fi

    touch "$HISTORY_FILE"

    # 기존에 받은 Wallhaven 파일도 이미 본 이미지로 간주합니다.
    if [ ! -f "$APPLIED_FILE" ]; then
      ${pkgs.findutils}/bin/find "$HOME/Pictures/Wallpapers" \
        -maxdepth 2 \
        -type f \
        -printf '%f\n' \
        | ${pkgs.gnused}/bin/sed -nE \
          's/^wallhaven[-_]([[:alnum:]]+)\.(jpg|jpeg|png|webp)$/\1/p' \
        | ${pkgs.coreutils}/bin/sort -u \
        > "$APPLIED_FILE.tmp" && mv "$APPLIED_FILE.tmp" "$APPLIED_FILE" || exit 1
    fi

    trap '${pkgs.coreutils}/bin/rm -f "$DOWNLOAD_FILE"' EXIT

    for _ in $(${pkgs.coreutils}/bin/seq 1 "$MAX_ATTEMPTS"); do
      TOPIC=$(printf '%s\n' "''${SEARCH_TOPICS[@]}" | ${pkgs.coreutils}/bin/shuf -n 1)
      case "$TOPIC" in
        space)
          CATEGORIES=100
          SPACE_KEYWORD=$(printf '%s\n' "''${SPACE_KEYWORDS[@]}" | ${pkgs.coreutils}/bin/shuf -n 1)
          QUERY="+\"$SPACE_KEYWORD\" -animation -anime -illustration -\"digital art\" -\"AI art\""
          ;;
        k-pop)
          CATEGORIES=001
          # 각 시도에서 하나를 선택하여 네 키워드를 모두 요구하는 AND 검색을 피합니다.
          PEOPLE_KEYWORD=$(printf '%s\n' "''${PEOPLE_KEYWORDS[@]}" | ${pkgs.coreutils}/bin/shuf -n 1)
          QUERY="+k-pop +\"$PEOPLE_KEYWORD\" -animation -anime"
          ;;
      esac

      RESPONSE=$(${pkgs.curl}/bin/curl \
        --fail \
        --location \
        --silent \
        --show-error \
        --retry 3 \
        --get \
        --data-urlencode "categories=$CATEGORIES" \
        --data-urlencode "atleast=2560x1440" \
        --data-urlencode "q=$QUERY" \
        "$API_URL") || continue

      while IFS=$'\t' read -r IMAGE_ID IMAGE_URL; do
        [ -n "$IMAGE_ID" ] || continue

        # 과거 밝기 검사에서 탈락한 인물 사진은 다시 선택할 수 있습니다.
        if ${pkgs.gnugrep}/bin/grep -Fqx "$IMAGE_ID" "$APPLIED_FILE" ||
           { [ "$TOPIC" = space ] && ${pkgs.gnugrep}/bin/grep -Fqx "$IMAGE_ID" "$HISTORY_FILE"; }; then
          continue
        fi

        if ! ${pkgs.curl}/bin/curl \
          --fail \
          --location \
          --silent \
          --show-error \
          --retry 3 \
          --output "$DOWNLOAD_FILE" \
          "$IMAGE_URL"; then
          continue
        fi

        if [ "$TOPIC" = space ]; then
          MEAN_LUMINANCE=$(${pkgs.imagemagick}/bin/magick \
            "$DOWNLOAD_FILE" \
            -colorspace Gray \
            -resize 1x1 \
            -format '%[fx:mean]' \
            info:) || continue

          # 밝아서 탈락한 후보도 기록하여 다음 실행에서 다시 받지 않습니다.
          echo "$IMAGE_ID" >> "$HISTORY_FILE"

          if ! ${pkgs.gawk}/bin/awk \
            -v luminance="$MEAN_LUMINANCE" \
            -v maximum="$MAX_MEAN_LUMINANCE" \
            'BEGIN { exit !(luminance <= maximum) }'; then
            continue
          fi
        fi

        FILENAME=$(${pkgs.coreutils}/bin/basename "$IMAGE_URL")
        FILEPATH="$WALLPAPER_DIR/$FILENAME"
        ${pkgs.coreutils}/bin/mv "$DOWNLOAD_FILE" "$FILEPATH" || exit 1

        # 검증을 통과한 새 이미지만 현재 실행 중인 Noctalia에 적용합니다.
        if ! ${config.programs.noctalia.package}/bin/noctalia msg wallpaper-set "$FILEPATH"; then
          echo "Failed to apply wallpaper: $FILEPATH" >&2
          exit 1
        fi
        echo "$IMAGE_ID" >> "$APPLIED_FILE"
        # 1.5초 배경 전환이 끝난 후 현재 이미지 외의 자동 다운로드 파일을 정리합니다.
        # 기본 배경, 사용자 파일, 다른 하위 폴더 및 심볼릭 링크는 보존합니다.
        ${pkgs.coreutils}/bin/sleep 2
        ${pkgs.findutils}/bin/find "$HOME/Pictures/Wallpapers" "$WALLPAPER_DIR" \
          -maxdepth 1 -regextype posix-extended -type f \
          -regex '.*/wallhaven[-_][[:alnum:]]+\.(jpg|jpeg|png|webp)' \
          ! -path "$FILEPATH" -delete
        echo "Applied $FILEPATH (topic: $TOPIC)"
        exit 0
      done < <(${pkgs.jq}/bin/jq -r '.data[]? | [.id, .path] | @tsv' <<< "$RESPONSE")
    done

    echo "No unseen wallpaper was found; keeping the current wallpaper." >&2
  '';
in
{
  # Niri 기본 배경화면 파일을 검은 배경화면 전용 디렉토리로 복사
  home.file."Pictures/Wallpapers/Black/niri_wallpaper.jpg".source = ../desktop/niri/niri_wallpaper.jpg;

  home.packages = [
    fetchWallhaven
  ];

  # 재활성화·재연결된 출력은 과거의 모니터별 경로 대신 현재 공통 배경을 사용합니다.
  systemd.user.services.noctalia-wallpaper-sync = {
    Unit = {
      Description = "Sync newly active Niri outputs to the current Noctalia wallpaper";
      After = [ "graphical-session.target" "noctalia.service" ];
      PartOf = [ "graphical-session.target" "noctalia.service" ];
      ConditionEnvironment = "NIRI_SOCKET";
    };
    Service = {
      ExecStart = "${wallpaperSync}/bin/noctalia-wallpaper-sync";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "noctalia.service" ];
  };

  # 주기적으로 새 배경화면을 Wallhaven에서 수집하는 Systemd 타이머 등록
  systemd.user.services.fetch-wallhaven = {
    Unit = {
      Description = "Automatically fetch a new wallpaper from Wallhaven";
      After = [ "noctalia.service" ];
      Requisite = [ "graphical-session.target" "noctalia.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${fetchWallhaven}/bin/fetch-wallhaven";
      Type = "oneshot";
    };
  };

  systemd.user.timers.fetch-wallhaven = {
    Unit = {
      Description = "Timer to automatically fetch a new wallpaper from Wallhaven";
      PartOf = [ "graphical-session.target" ];
    };
    Timer = {
      OnActiveSec = "5sec";       # 타이머 활성화 후 첫 배경화면을 즉시 검색
      OnUnitActiveSec = "15min"; # 이후 15분마다 실행
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  systemd.user.services.noctalia.Service.ExecStartPre = [ "${migrateLockWidgets}" ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # 기본 설정 (배경화면과 독립적인 Catppuccin 테마)
    settings = {
      # Noctalia Shell의 설정 인터페이스(GUI)를 통해 변경한 내용을 
      # 나중에 여기에 복사하여 영구적으로 유지할 수 있습니다.
      # 별도 TOML 프리셋에서 L-frame과 floating panel 구성을 불러옵니다.
      bar = lFramePreset.bar;
      shell = lFramePreset.shell;

      # 현재 인터넷 회선의 공인 IP로 세 기기의 대략적인 위치를 자동으로 찾습니다.
      location.auto_locate = true;

      # 알림음과 UI 사운드 활성화
      audio = {
        enable_sounds = true;
        sound_volume = 1.0;
        sound_theme = "freedesktop";
      };

      # 테마 설정 (v5 규격)
      theme = {
        mode = "dark";
        source = "builtin";
        # 내장 Catppuccin 팔레트의 dark 모드는 Mocha입니다.
        builtin = "Catppuccin";
      };

      # 배경화면 설정 (v5 규격)
      wallpaper = {
        enabled = true;
        directory = "~/Pictures/Wallpapers/Black";
        transition = [
          "fade"
          "wipe"
          "disc"
          "stripes"
          "zoom"
          "honeycomb"
        ];
        transition_duration = 1500;
        transition_on_startup = true;

        # 기본/초기 배경화면 경로 지정
        default = {
          path = "~/Pictures/Wallpapers/Black/niri_wallpaper.jpg";
        };

        # 중복 선택을 방지하기 위해 변경은 fetch-wallhaven만 담당합니다.
        automation = {
          enabled = false;
          interval_seconds = 1800;
          order = "random";
          recursive = true;
        };
      };

      # 잠금 직전 화면에 흐림 효과와 틴트를 적용합니다.
      lockscreen = {
        blurred_desktop = true;
        blur_intensity = 0.2;
        tint_intensity = 0.3;
      };

      # 로그인 패널 위에 디지털 시각과 날짜를 표시합니다.
      lockscreen_widgets = {
        enabled = true;
        widget_order = builtins.attrNames lockWidgets;
        widget = lockWidgets;
      };

      # 오버뷰 배경화면에도 아주 약한 블러만 적용합니다.
      backdrop = {
        enabled = true;
        blur_intensity = 0.05;
        tint_intensity = 0.25;
      };
    };
  };
}
