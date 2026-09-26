#!/usr/bin/env python3
"""Manage only our notify entry in Codex's mutable user configuration."""

import argparse
import os
from pathlib import Path
import tempfile

import tomlkit


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--command", required=True)
    parser.add_argument("--disable", action="store_true")
    args = parser.parse_args()
    path = args.config
    if path.is_symlink():
        raise SystemExit("codex-telegram: manage notify in the existing config symlink's source")
    original = path.read_text() if path.exists() else ""
    document = tomlkit.parse(original)
    desired = [args.command]
    current = document.get("notify")
    if args.disable:
        if current != desired:
            return
        del document["notify"]
    else:
        if current == desired:
            return
        if current is not None:
            raise SystemExit("codex-telegram: existing notify hook found; combine hooks before enabling")
        document["notify"] = desired
    updated = tomlkit.dumps(document)
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        backup = path.with_name(path.name + ".before-telegram")
        if not backup.exists():
            fd = os.open(backup, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            with os.fdopen(fd, "w") as stream:
                stream.write(original)
    fd, temporary = tempfile.mkstemp(dir=path.parent, prefix=".codex-telegram-")
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(updated)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


if __name__ == "__main__":
    main()
