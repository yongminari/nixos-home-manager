"""Lower a Niri output's refresh rate before DPMS; restore after activity."""

import argparse
from contextlib import contextmanager
import fcntl
import json
import os
from pathlib import Path
import subprocess
import time


class IdleRefresh:
    def __init__(self, runtime, session, target, niri, wake_delay=6):
        self.directory = Path(runtime) / "niri-idle-refresh"
        self.directory.mkdir(mode=0o700, exist_ok=True)
        self.state_path = self.directory / "state.json"
        self.session = session
        self.target = target
        self.niri = niri
        self.wake_delay = wake_delay

    @contextmanager
    def locked(self):
        with (self.directory / "lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            yield

    def msg(self, *args):
        result = subprocess.run(
            [self.niri, "msg", *args], capture_output=True, text=True,
            check=True, timeout=10,
        )
        return result.stdout

    def output(self):
        outputs = json.loads(self.msg("--json", "outputs"))
        for output in outputs.values():
            identity = " ".join(str(output.get(k) or "Unknown")
                                for k in ("make", "model", "serial"))
            if self.target in (output["name"], identity):
                if output["current_mode"] is not None:
                    return output
        raise RuntimeError("configured output is not active")

    @staticmethod
    def mode_name(mode):
        return (f'{mode["width"]}x{mode["height"]}'
                f'@{mode["refresh_rate"] / 1000:.3f}')

    def read(self):
        if not self.state_path.exists():
            return None
        state = json.loads(self.state_path.read_text())
        if state["session"] != self.session:
            self.state_path.unlink()
            return None
        return state

    def write(self, state):
        temporary = self.directory / "state.tmp"
        temporary.write_text(json.dumps(state))
        temporary.replace(self.state_path)

    def set_mode(self, output, mode):
        self.msg("output", output["name"], "mode", self.mode_name(mode))

    def prepare(self):
        with self.locked():
            if self.read() is not None:
                return
            output = self.output()
            original = output["modes"][output["current_mode"]]
            if output.get("is_custom_mode"):
                raise RuntimeError("custom modes are not supported; skipping DPMS")
            candidates = [m for m in output["modes"]
                          if (m["width"], m["height"]) ==
                          (original["width"], original["height"])
                          and abs(m["refresh_rate"] - 60000) < 1000]
            if not candidates:
                raise RuntimeError("no 60 Hz mode at current resolution; skipping DPMS")
            low = min(candidates, key=lambda m: abs(m["refresh_rate"] - 60000))
            if original["refresh_rate"] <= low["refresh_rate"]:
                low = original
            state = dict(session=self.session, original=original, low=low,
                         phase="prepared", token=time.monotonic_ns())
            # Save first so resume can recover even if mode setting times out.
            self.write(state)
            if original != low:
                self.set_mode(output, low)
            print("idle-refresh: prepared", self.mode_name(low), flush=True)

    def off(self):
        with self.locked():
            state = self.read()
            # A late timeout callback must not turn the screen off after resume.
            if state is None or state["phase"] != "prepared":
                return
            output = self.output()
            current = output["modes"][output["current_mode"]]
            if current != state["low"]:
                raise RuntimeError("60 Hz transition not confirmed; skipping DPMS")
            state["phase"] = "off"
            self.write(state)
            self.msg("action", "power-off-monitors")
            print("idle-refresh: powered off at low refresh", flush=True)

    def resume(self):
        with self.locked():
            state = self.read()
            if state is None:
                return
            token = state["token"]
            if state["phase"] == "off":
                # Wake before restoring the expensive display mode.
                self.msg("action", "power-on-monitors")
                state["restore_at"] = time.monotonic() + self.wake_delay
                state["phase"] = "waking"
                self.write(state)
            deadline = state.get("restore_at", 0)
        # Never hold the lock while waiting: duplicate resume callbacks may run.
        time.sleep(max(0, deadline - time.monotonic()))
        for attempt in range(10):
            with self.locked():
                latest = self.read()
                if latest is None or latest["token"] != token:
                    return
                try:
                    output = self.output()
                except RuntimeError:
                    output = None
                if output is not None:
                    current = output["modes"][output["current_mode"]]
                    # Preserve a mode explicitly changed by the user meanwhile.
                    if current == latest["low"] and current != latest["original"]:
                        self.set_mode(output, latest["original"])
                    self.state_path.unlink()
                    print("idle-refresh: restored (or kept user-selected mode)", flush=True)
                    return
            time.sleep(1)
        raise RuntimeError("output still absent; keeping saved mode for a later resume")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--niri", required=True)
    parser.add_argument("--target", required=True)
    parser.add_argument("action", choices=("prepare", "off", "resume"))
    args = parser.parse_args()
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    session = os.environ.get("NIRI_SOCKET")
    if not runtime or not session:
        return
    os.umask(0o077)
    controller = IdleRefresh(runtime, session, args.target, args.niri)
    getattr(controller, args.action)()


if __name__ == "__main__":
    main()
