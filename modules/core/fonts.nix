{ pkgs, ... }:

let
  jalpullineun-oneul = pkgs.stdenvNoCC.mkDerivation {
    pname = "jalpullineun-oneul";
    version = "2021-01-11";
    src = pkgs.fetchurl {
      url = "https://www.jjtissue.com/design/mra2024/font/Jalpullineun_Oneul_Fonts.zip";
      hash = "sha256-yaqt74UZ+gr5FcjQfXm0hFUGfecYa1d3bgJAqKSe9ac=";
    };
    nativeBuildInputs = [ pkgs.python3 ];
    dontUnpack = true;
    # ZIP의 한글 파일명 인코딩에 의존하지 않고 원본 TTF를 설치합니다.
    installPhase = ''
      runHook preInstall
      python3 - <<'PY'
      import os
      import pathlib
      import zipfile

      target = pathlib.Path(os.environ["out"]) / "share/fonts/truetype"
      target.mkdir(parents=True)
      with zipfile.ZipFile(os.environ["src"]) as archive:
          font, = [name for name in archive.namelist() if name.endswith(".ttf")]
          (target / "Jalpullineunoneul.ttf").write_bytes(archive.read(font))
      PY
      runHook postInstall
    '';
    meta = {
      description = "잘풀리는 오늘체";
      homepage = "https://www.jjtissue.com/shop/page.html?id=6077";
      license = pkgs.lib.licenses.unfree;
      platforms = pkgs.lib.platforms.all;
    };
  };
in
{
  home.packages = with pkgs; [
    nerd-fonts.ubuntu-mono
    monaspace
    nerd-fonts.jetbrains-mono
    jalpullineun-oneul
  ];

  fonts.fontconfig = {
    defaultFonts = {
      monospace = [ "Maple Mono NF" "Jalpullineunoneul" "D2Coding" ];
      sansSerif = [ "Maple Mono NF" "Jalpullineunoneul" "D2Coding" ];
      serif = [ "Maple Mono NF" "Jalpullineunoneul" "D2Coding" ];
    };
    # GTK 등 Maple Mono를 직접 지정한 앱에도 한글 대체 글꼴을 적용합니다.
    configFile.jalpullineun-oneul = {
      priority = 90;
      text = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <match target="pattern">
            <test name="family" compare="eq"><string>Maple Mono NF</string></test>
            <edit name="family" mode="append" binding="strong">
              <string>Jalpullineunoneul</string>
            </edit>
          </match>
        </fontconfig>
      '';
    };
  };
}
