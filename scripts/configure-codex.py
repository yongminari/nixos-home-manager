#!/usr/bin/env python3
"""Merge Home Manager settings into Codex's mutable user configuration."""

import argparse
from collections.abc import Mapping
import os
from pathlib import Path
import tempfile

import tomlkit


def merge(document, settings):
    for key, value in settings.items():
        if isinstance(value, Mapping):
            if key not in document:
                document[key] = tomlkit.table()
            if not isinstance(document[key], Mapping):
                raise ValueError(f"codex: expected a table for {key}")
            merge(document[key], value)
        else:
            document[key] = value


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--settings", type=Path, required=True)
    args = parser.parse_args()
    path = args.config
    if path.is_symlink():
        raise SystemExit("codex: config.toml must be a writable regular file, not a symlink")
    original = path.read_text() if path.exists() else ""
    document = tomlkit.parse(original)
    merge(document, tomlkit.parse(args.settings.read_text()))
    updated = tomlkit.dumps(document)
    if updated == original:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        backup = path.with_name(path.name + ".before-home-manager")
        if not backup.exists():
            fd = os.open(backup, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            with os.fdopen(fd, "w") as stream:
                stream.write(original)
    fd, temporary = tempfile.mkstemp(dir=path.parent, prefix=".codex-settings-")
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(updated)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


if __name__ == "__main__":
    main()
