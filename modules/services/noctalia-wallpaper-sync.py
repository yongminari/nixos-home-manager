"""Apply Noctalia's current shared wallpaper when a Niri output becomes active."""

import json
from pathlib import Path
import subprocess
import time


def noctalia(*args):
    result = subprocess.run(
        ["noctalia", "msg", *args], check=True, capture_output=True,
        text=True, timeout=5,
    )
    value = result.stdout.strip()
    if value.startswith("error:"):
        raise RuntimeError(value)
    return value


def sync_output(output):
    # Niri can announce the output before Noctalia has received its Wayland event.
    for attempt in range(10):
        try:
            wallpaper = noctalia("wallpaper-get")
            if not Path(wallpaper).is_file():
                raise RuntimeError("The shared wallpaper is not a regular file")
            if noctalia("wallpaper-get", output) != wallpaper:
                noctalia("wallpaper-set", output, wallpaper)
                print(f"Synchronized wallpaper for {output}", flush=True)
            return
        except (OSError, RuntimeError, subprocess.SubprocessError):
            if attempt == 9:
                raise
            time.sleep(0.3)


def handle_event(event, active):
    if "WorkspacesChanged" not in event:
        return active
    outputs = {
        workspace["output"]
        for workspace in event["WorkspacesChanged"]["workspaces"]
        if workspace.get("output")
    }
    for output in sorted(outputs - active):
        sync_output(output)
    return outputs


def main():
    active = set()
    process = subprocess.Popen(
        ["niri", "msg", "--json", "event-stream"],
        stdout=subprocess.PIPE, text=True,
    )
    try:
        for line in process.stdout:
            active = handle_event(json.loads(line), active)
        raise RuntimeError("Niri event stream closed")
    finally:
        process.terminate()
        process.wait(timeout=5)


if __name__ == "__main__":
    main()
