"""Migrate the old clock list before Noctalia reads its GUI overrides."""

import os
from pathlib import Path
import stat
import sys
from tempfile import NamedTemporaryFile

import tomlkit


def migrate(state_file, clocks):
    if not state_file.exists():
        return
    original = state_file.read_text()
    document = tomlkit.parse(original)
    section = document.get("lockscreen_widgets")
    if section is None:
        return

    legacy = {"analog_clock", "analog_clock_right"}
    widgets = section.get("widget", {})
    order = section.get("widget_order")
    if order is not None:
        section["widget_order"] = clocks + [key for key in order if key not in legacy and key not in clocks]
    for key in legacy:
        widgets.pop(key, None)
    if section.get("enabled") is False:
        del section["enabled"]
    updated = tomlkit.dumps(document)
    if updated == original:
        return
    with NamedTemporaryFile(mode="w", dir=state_file.parent, delete=False) as stream:
        os.fchmod(stream.fileno(), stat.S_IMODE(state_file.stat().st_mode))
        stream.write(updated)
    os.replace(stream.name, state_file)


if __name__ == "__main__":
    state_home = Path(os.getenv("XDG_STATE_HOME") or Path.home() / ".local/state")
    directory = state_home / "noctalia"
    marker = directory / ".digital-lock-clock-migrated"
    if not marker.exists():
        directory.mkdir(parents=True, exist_ok=True)
        migrate(directory / "settings.toml", sys.argv[1:])
        marker.touch()
