#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -x "$SCRIPT_DIR/update-codex.sh" ]; then
    "$SCRIPT_DIR/update-codex.sh"
    "$SCRIPT_DIR/update-agy.sh"
else
    "$SCRIPT_DIR/update-codex"
    "$SCRIPT_DIR/update-agy"
fi
