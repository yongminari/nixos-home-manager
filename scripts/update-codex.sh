#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${CODEX_INSTALL_DIR:-$HOME/.local/bin}"
INSTALLER_PATH=$(mktemp)
trap 'rm -f "$INSTALLER_PATH"' EXIT

echo "Downloading the official Codex CLI installer..."
curl -fsSL --retry 3 --output "$INSTALLER_PATH" "https://chatgpt.com/codex/install.sh"

echo "Installing or updating Codex CLI..."
CODEX_INSTALL_DIR="$INSTALL_DIR" CODEX_NON_INTERACTIVE=1 sh "$INSTALLER_PATH"

if [ ! -x "$INSTALL_DIR/codex" ]; then
    echo "Error: Codex CLI was not installed at $INSTALL_DIR/codex." >&2
    exit 1
fi

echo "Codex CLI $("$INSTALL_DIR/codex" --version) installed at $INSTALL_DIR/codex."
