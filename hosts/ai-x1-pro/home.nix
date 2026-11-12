{ pkgs, ... }:

{
  # 컨트롤센터·런처 등 바 이외 Noctalia UI의 호스트별 배율입니다.
  programs.noctalia.settings.accessibility.ui_scale = 1.5;

  # Qt6/NVIDIA의 Wayland EGL 컨텍스트 오류(3009)를 XWayland + GLX로 우회합니다.
  programs.sioyek.package = pkgs.symlinkJoin {
    name = "sioyek-xwayland-${pkgs.sioyek.version}";
    paths = [ pkgs.sioyek ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/sioyek"
      makeWrapper ${pkgs.sioyek}/bin/sioyek "$out/bin/sioyek" \
        --set QT_QPA_PLATFORM xcb \
        --set QT_XCB_GL_INTEGRATION xcb_glx

      rm "$out/share/applications/sioyek.desktop"
      cp ${pkgs.sioyek}/share/applications/sioyek.desktop "$out/share/applications/sioyek.desktop"
      chmod u+w "$out/share/applications/sioyek.desktop"
      substituteInPlace "$out/share/applications/sioyek.desktop" \
        --replace-fail "Exec=sioyek %f" "Exec=$out/bin/sioyek %f" \
        --replace-fail "TryExec=sioyek" "TryExec=$out/bin/sioyek"
    '';
    meta = pkgs.sioyek.meta;
  };

  # AMD/NVIDIA 혼합 구성: GLX/GBM/VA-API 공급자는 자동 선택합니다.
  # NVIDIA를 명시할 앱은 nvidia-offload로 실행합니다(GLX/Vulkan).
  # LIBVA_DRIVER_NAME 전역 지정은 AMD 영상 가속 선택까지 덮어씁니다.
  local.desktop = {
    # DP 절전 복귀 우회: 꺼지기 15초 전 60Hz, 입력 시 기존 주사율 복원.
    monitorOffTimeout = 900;
    monitorIdleRefresh = {
      enable = true;
      blur = true;
      output = "Hexium Ltd. 40LGD5KGM 0000000000000";
    };
    scale = "1.0";
    isLaptop = false;
    outputs = {
      left = "Hexium Ltd. 40LGD5KGM 0000000000000";
      right = "Samsung Electric Company SAMSUNG Unknown";
    };
    extraConfig = ''
      output "Hexium Ltd. 40LGD5KGM 0000000000000" {
          mode "5120x2160@120"
          scale 1.25
          position x=0 y=0
      }
      output "Samsung Electric Company SAMSUNG Unknown" {
          off
          mode "3840x2160@60"
          scale 1.25
          position x=4096 y=0
      }
    '';
  };
}
