{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # [검색 및 파일 제어 도구]
    ripgrep 
    fd 
    unzip 
    gh              # GitHub CLI
    glab            # GitLab CLI
    vcs2l           # VCS tool for multiple repositories (replacement for vcstool)
    lazydocker      # Docker TUI 관리
    (stdenv.mkDerivation rec {
      pname = "agy";
      version = "1.1.1";

      src = let
        hashes = {
          x86_64-linux = "sha512-/OutgkfgRTCX4rJtg5NxyI3wQOb7GPrD/YByhRGUc5z0YkBBRptX9Sm8nC4RQKbOTNXnFE5k5u/FYFqfEKhitw==";
          aarch64-linux = "sha512-bT2Jx7iNTiLi7vk3znMTRSmWV6x6FCNqk6X53OZ+tyUYRczJgEsKsYgRJf9hZTEc5zxpM8E3bsO5ZmWalHU+YA==";
        };
        urls = {
          x86_64-linux = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.1-6269367663591424/linux-x64/cli_linux_x64.tar.gz";
          aarch64-linux = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.1-6269367663591424/linux-arm/cli_linux_arm64.tar.gz";
        };
      in fetchurl {
        url = urls.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
        hash = hashes.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
      };

      nativeBuildInputs = [ installShellFiles ];

      sourceRoot = ".";

      installPhase = ''
        install -Dm755 antigravity $out/bin/agy
      '';

      meta = {
        description = "Antigravity CLI tool";
        homepage = "https://antigravity.google";
      };
    })
    
    # [개발 보조 도구 (LSP/Parsers)]
    tree-sitter   # Tree-sitter CLI (Fix checkhealth error)
    nil           # Nix Language Server
    ast-grep      # ast-grep CLI
    lua51Packages.jsregexp # Luasnip dependency
    gopls         # Go LSP
    clang-tools   # clangd 등 (헤더 검색 등 에디터용)
    pyright       # Python LSP
    bash-language-server # Bash/Shell LSP
    yaml-language-server # YAML LSP
    taplo         # TOML LSP
    vscode-langservers-extracted # JSON, HTML, CSS LSP
    cmake-language-server # CMake LSP
    autotools-language-server # Makefile, autotools LSP

    # [현대적 대체 도구]
    sd              # sed 대체 (find & replace)
    xh              # curl/httpie 대체

    # [Keyboard Development]
    qmk             # QMK Firmware CLI
    vial            # Vial GUI for keyboard configuration
  ];
}
