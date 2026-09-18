{ inputs, pkgs, config, ... }:

let
  lFramePreset = builtins.fromTOML (builtins.readFile ./noctalia/l-frame.toml);

  fetchWallhaven = pkgs.writeShellScriptBin "fetch-wallhaven" ''
    set -u

    WALLPAPER_DIR="$HOME/Pictures/Wallpapers/Black"
    STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/fetch-wallhaven"
    HISTORY_FILE="$STATE_DIR/seen-ids"
    DOWNLOAD_FILE="$STATE_DIR/candidate.download"
    API_URL="https://wallhaven.cc/api/v1/search?categories=111&purity=100&colors=000000&sorting=random"
    MAX_MEAN_LUMINANCE="0.28"
    MAX_ATTEMPTS=5

    mkdir -p "$WALLPAPER_DIR" "$STATE_DIR"
    touch "$HISTORY_FILE"

    # 기존에 받은 Wallhaven 파일도 이미 본 이미지로 간주합니다.
    if [ ! -s "$HISTORY_FILE" ]; then
      ${pkgs.findutils}/bin/find "$HOME/Pictures/Wallpapers" \
        -maxdepth 2 \
        -type f \
        -printf '%f\n' \
        | ${pkgs.gnused}/bin/sed -nE \
          's/^wallhaven[-_]([[:alnum:]]+)\.(jpg|jpeg|png|webp)$/\1/p' \
        | ${pkgs.coreutils}/bin/sort -u \
        >> "$HISTORY_FILE"
    fi

    # 타이머와 수동 단축키가 동시에 실행되어 같은 이미지를 처리하지 않도록 합니다.
    exec 9>"$STATE_DIR/lock"
    if ! ${pkgs.util-linux}/bin/flock -n 9; then
      echo "A wallpaper fetch is already running; keeping the current wallpaper." >&2
      exit 0
    fi

    trap '${pkgs.coreutils}/bin/rm -f "$DOWNLOAD_FILE"' EXIT

    for _ in $(${pkgs.coreutils}/bin/seq 1 "$MAX_ATTEMPTS"); do
      RESPONSE=$(${pkgs.curl}/bin/curl \
        --fail \
        --location \
        --silent \
        --show-error \
        --retry 3 \
        "$API_URL") || continue

      while IFS=$'\t' read -r IMAGE_ID IMAGE_URL; do
        [ -n "$IMAGE_ID" ] || continue

        # 한 번 검사하거나 표시한 Wallhaven 이미지는 다시 사용하지 않습니다.
        if ${pkgs.gnugrep}/bin/grep -Fqx "$IMAGE_ID" "$HISTORY_FILE"; then
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

        FILENAME=$(${pkgs.coreutils}/bin/basename "$IMAGE_URL")
        FILEPATH="$WALLPAPER_DIR/$FILENAME"
        ${pkgs.coreutils}/bin/mv "$DOWNLOAD_FILE" "$FILEPATH"

        # 검증을 통과한 새 이미지만 현재 실행 중인 Noctalia에 적용합니다.
        ${config.programs.noctalia.package}/bin/noctalia msg wallpaper-set "$FILEPATH"
        echo "Applied $FILEPATH (mean luminance: $MEAN_LUMINANCE)"
        exit 0
      done < <(${pkgs.jq}/bin/jq -r '.data[]? | [.id, .path] | @tsv' <<< "$RESPONSE")
    done

    echo "No unseen black wallpaper was found; keeping the current wallpaper." >&2
  '';
in
{
  # Niri 기본 배경화면 파일을 검은 배경화면 전용 디렉토리로 복사
  home.file."Pictures/Wallpapers/Black/niri_wallpaper.jpg".source = ../desktop/niri/niri_wallpaper.jpg;

  home.packages = [
    fetchWallhaven
  ];

  # 주기적으로 검증된 검은 배경화면을 Wallhaven에서 수집하는 Systemd 타이머 등록
  systemd.user.services.fetch-wallhaven = {
    Unit = {
      Description = "Automatically fetch a new wallpaper from Wallhaven";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${fetchWallhaven}/bin/fetch-wallhaven";
      Type = "oneshot";
    };
  };

  systemd.user.timers.fetch-wallhaven = {
    Unit = {
      Description = "Timer to automatically fetch a new wallpaper from Wallhaven";
    };
    Timer = {
      OnActiveSec = "5sec";       # 타이머 활성화 후 첫 배경화면을 즉시 검색
      OnUnitActiveSec = "30min"; # 이후 30분마다 실행
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
    
    # 기본 설정 (Matugen 기반으로 테마가 자동 생성되나 필요시 커스텀 가능)
    settings = {
      # Noctalia Shell의 설정 인터페이스(GUI)를 통해 변경한 내용을 
      # 나중에 여기에 복사하여 영구적으로 유지할 수 있습니다.
      # 별도 TOML 프리셋에서 L-frame과 floating panel 구성을 불러옵니다.
      bar = lFramePreset.bar;
      shell = lFramePreset.shell;

      # 테마 설정 (v5 규격)
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Ayu";
      };

      # 배경화면 설정 (v5 규격)
      wallpaper = {
        enabled = true;
        directory = "~/Pictures/Wallpapers/Black";
        transition = [
          "fade"
          "pixelate"
          "blur"
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

      # 오버뷰 배경화면에도 아주 약한 블러만 적용합니다.
      backdrop = {
        enabled = true;
        blur_intensity = 0.05;
        tint_intensity = 0.25;
      };
    };
  };
}
