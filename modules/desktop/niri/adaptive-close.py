"""Mod+Q 전용: 타일 창을 축소·중앙 이동한 뒤 고정된 ID로 닫습니다."""
import fcntl
import json
import os
from pathlib import Path
import queue
import subprocess
import sys
import tempfile
import threading
import time


def choose_side(windows, target):
    others = [w for w in windows if w["id"] != target["id"]
              and w.get("workspace_id") == target.get("workspace_id")]
    if not others:
        return 0.0
    position = target.get("layout", {}).get("pos_in_scrolling_layout")
    if target.get("is_floating") or not position:
        return 1.0
    tiled = [w for w in others if not w.get("is_floating")
             and w.get("layout", {}).get("pos_in_scrolling_layout")]
    col = position[0]
    if any(w["layout"]["pos_in_scrolling_layout"][0] == col for w in tiled):
        return 0.0
    left = [w for w in tiled if w["layout"]["pos_in_scrolling_layout"][0] < col]
    right = [w for w in tiled if w["layout"]["pos_in_scrolling_layout"][0] > col]
    if not left:
        return 1.0
    if not right:
        return -1.0
    # Niri의 내부 '이전 열 복원' 상태는 IPC에 없으므로 인접 열의 최근 포커스로 추정합니다.
    left_col = max(w["layout"]["pos_in_scrolling_layout"][0] for w in left)
    right_col = min(w["layout"]["pos_in_scrolling_layout"][0] for w in right)
    def stamp(w):
        t = w.get("focus_timestamp") or {}
        return t.get("secs", 0), t.get("nanos", 0)
    left_time = max(stamp(w) for w in left if w["layout"]["pos_in_scrolling_layout"][0] == left_col)
    right_time = max(stamp(w) for w in right if w["layout"]["pos_in_scrolling_layout"][0] == right_col)
    return -1.0 if left_time > right_time else 1.0


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



def atomic_write(path, text):
    fd, name = tempfile.mkstemp(prefix=".genie-close-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(text)
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def load_shader(path, content):
    if path.exists() and path.read_text() == content:
        return
    events = queue.Queue()
    reader = subprocess.Popen(["niri", "msg", "--json", "event-stream"], stdout=subprocess.PIPE, text=True)
    def read_events():
        for line in reader.stdout:
            try:
                event = json.loads(line)
                if "ConfigLoaded" in event:
                    events.put(event["ConfigLoaded"])
            except ValueError:
                pass
    threading.Thread(target=read_events, daemon=True).start()
    try:
        events.get(timeout=3)
        atomic_write(path, content)
        niri("action", "load-config-file")
        if events.get(timeout=3)["failed"]:
            raise RuntimeError("Niri rejected the directional close config")
    finally:
        reader.terminate()
        reader.wait(timeout=3)


def main():
    template = Path(sys.argv[1]).read_text()
    path = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "niri/genie-close.kdl"
    runtime = Path(os.environ["XDG_RUNTIME_DIR"])
    with (runtime / "niri-adaptive-close.lock").open("a") as gate, \
            (runtime / "niri-close-animations.lock").open("a") as animations:
        # 입력별로 대상 선택과 포커스 인계까지만 직렬화합니다.
        fcntl.flock(gate, fcntl.LOCK_EX)
        windows = json.loads(niri("windows"))
        target = next((w for w in windows if w["is_focused"]), None)
        if target is None:
            return
        side = choose_side(windows, target)
        if "--explain" in sys.argv[2:]:
            print(json.dumps({"window_id": target["id"], "direction": {-1.0: "left", 0.0: "center", 1.0: "right"}[side]}))
            return
        try:
            fcntl.flock(animations, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            pass  # Niri의 닫기 셰이더는 전역이므로 겹치는 창은 첫 창의 방향을 사용합니다.
        else:
            load_shader(path, template.replace("@SIDE@", str(side)))
        fcntl.flock(animations, fcntl.LOCK_SH)
        try:
            if not prepare_close(target):
                return
            hand_off_focus(target)
            fcntl.flock(gate, fcntl.LOCK_UN)

            # floating 전환 애니메이션이 진행되는 동안 바로 닫기를 요청합니다.
            if not any(w["id"] == target["id"] and w["is_floating"]
                       for w in json.loads(niri("windows"))):
                return
            niri("action", "close-window", "--id", str(target["id"]))
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                if not any(w["id"] == target["id"] for w in json.loads(niri("windows"))):
                    # 550ms 애니메이션이 끝난 뒤 공통 방향을 복원합니다.
                    time.sleep(0.65)
                    break
                time.sleep(0.1)
        finally:
            fcntl.flock(gate, fcntl.LOCK_EX)
            fcntl.flock(animations, fcntl.LOCK_UN)
            try:
                fcntl.flock(animations, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                pass
            else:
                load_shader(path, template.replace("@SIDE@", "1.0"))


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError, queue.Empty) as error:
        print(f"niri-adaptive-close: {error}", file=sys.stderr)
        sys.exit(1)
