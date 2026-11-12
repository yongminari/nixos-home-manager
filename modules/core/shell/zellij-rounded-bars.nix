{ pkgs }:

# 기본 플러그인의 정보와 단축키 처리는 유지하고 출력 양 끝만 둥글게 합니다.
# Zellij 업데이트 시 같은 버전으로 재빌드되며, 소스 변경에 따라 패치 보수가 필요합니다.
pkgs.pkgsCross.wasi32.rustPlatform.buildRustPackage {
  pname = "zellij-rounded-bars";
  inherit (pkgs.zellij-unwrapped) version src cargoDeps;

  patches = [ ./zellij-rounded-bars.patch ];
  # WASI에는 C 링커가 아닌 Rust와 같은 LLVM 버전의 LLD가 필요합니다.
  buildPhase = ''
    runHook preBuild
    export CARGO_TARGET_WASM32_WASIP1_LINKER=${pkgs.rustc.llvmPackages.lld}/bin/lld
    cargo build --offline --release --target wasm32-wasip1 \
      -j "$NIX_BUILD_CORES" -p tab-bar -p status-bar
    runHook postBuild
  '';
  doCheck = false; # WASI 플러그인은 Zellij 안에서 검증합니다.

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp target/wasm32-wasip1/release/{tab-bar,status-bar}.wasm $out/
    runHook postInstall
  '';
}
