{ config, pkgs, ... }:

{
  # --- [ROS 2 Development Tools] ---
  home.packages = with pkgs; [
    # ROS 2 개발용 Distrobox LSP 래퍼
    (writeShellScriptBin "clangd-distrobox" ''
      CONTAINER=''${DISTROBOX_NAME:-ros2-jazzy}
      exec distrobox enter "$CONTAINER" -- /bin/bash -c "
        [ -f ~/.ros_bashrc ] && . ~/.ros_bashrc 2>/dev/null
        [ -f /opt/ros/jazzy/setup.bash ] && . /opt/ros/jazzy/setup.bash 2>/dev/null
        exec clangd \"\$@\"
      " _ "$@"
    '')
    # 컨테이너 진입용
    # .bashrc 대신 .ros_bashrc를 읽어 로컬 설정과 충돌을 방지합니다.
    (writeShellScriptBin "ros-enter" ''
      CONTAINER=''${DISTROBOX_NAME:-ros2-jazzy}
      exec distrobox enter "$CONTAINER" -- bash --rcfile ~/.ros_bashrc
    '')
  ];
}
