{ config, pkgs, ... }:

{
  # --- [ROS 2 Development Tools] ---
  home.packages = with pkgs; [
    # ROS 2 개발용 Distrobox LSP 래퍼
    # 컨테이너(ros-jazzy) 내부의 clangd를 호스트에서 실행하는 것처럼 연결합니다.
    (writeShellScriptBin "clangd-distrobox" ''
      exec distrobox enter ros-jazzy -- clangd "$@"
    '')
  ];
}
