"""Mod+Q 전용: 타일 창을 축소·중앙 이동한 뒤 고정된 ID로 닫습니다."""
import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys
import time


def niri(*args):
    return subprocess.check_output(["niri", "msg", "--json", *args], text=True, timeout=3)


def prepare_close(target):
    if target.get("is_floating"):
        return True
    window_id = str(target["id"])
    # Mod+W와 같은 10% 축소입니다. 종료 경로에서는 토글하거나 포커스를 재조회하지 않습니다.
    size = [max(1, int(value * 0.9 + 0.5))
            for value in target["layout"]["window_size"]]
    niri("action", "move-window-to-floating", "--id", window_id)
    niri("action", "set-window-width", "--id", window_id, str(size[0]))
    niri("action", "set-window-height", "--id", window_id, str(size[1]))
    # 앱의 크기 반영만 짧게 기다립니다. 스프링이 끝날 때까지 기다리지 않습니다.
    deadline = time.monotonic() + 0.12
    while True:
        current = next((w for w in json.loads(niri("windows"))
                        if w["id"] == target["id"]), None)
        if current is None or not current.get("is_floating"):
            return False
        if current["layout"]["window_size"] == size or time.monotonic() >= deadline:
            break
        time.sleep(0.01)
    # 최소 크기로 제한된 앱도 실제 크기로 정렬합니다.
    niri("action", "center-window", "--id", window_id)
    return True


def hand_off_focus(target):
    windows = json.loads(niri("windows"))
    current = next((w for w in windows if w["id"] == target["id"]), None)
    if current is None or not current["is_floating"]:
        return
    if current["is_focused"] and any(
        not w["is_floating"] and w["workspace_id"] == current["workspace_id"]
        for w in windows
    ):
        niri("action", "focus-tiling")


def main():
    runtime = Path(os.environ["XDG_RUNTIME_DIR"])
    with (runtime / "niri-adaptive-close.lock").open("a") as gate:
        fcntl.flock(gate, fcntl.LOCK_EX)
        windows = json.loads(niri("windows"))
        target = next((w for w in windows if w["is_focused"]), None)
        if target is None or not prepare_close(target):
            return
        hand_off_focus(target)

    # 포커스가 이동해도 처음 선택한 창만 닫습니다.
    if any(w["id"] == target["id"] and w["is_floating"]
           for w in json.loads(niri("windows"))):
        niri("action", "close-window", "--id", str(target["id"]))


if __name__ == "__main__":
    if len(sys.argv) != 1:
        sys.exit("usage: niri-adaptive-close")
    try:
        main()
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"niri-adaptive-close: {error}", file=sys.stderr)
        sys.exit(1)
