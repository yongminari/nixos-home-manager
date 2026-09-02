#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"

case "$(uname -m)" in
    x86_64)
        MANIFEST_URL="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_amd64.json"
        ;;
    aarch64 | arm64)
        MANIFEST_URL="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_arm64.json"
        ;;
    *)
        echo "Error: Unsupported architecture: $(uname -m)" >&2
        exit 1
        ;;
esac

echo "Checking for the latest Antigravity CLI..."
MANIFEST=$(curl -fsSL --retry 3 "$MANIFEST_URL")
LATEST_VERSION=$(jq -er '.version' <<<"$MANIFEST")
DOWNLOAD_URL=$(jq -er '.url' <<<"$MANIFEST")
EXPECTED_SHA512=$(jq -er '.sha512 | ascii_downcase' <<<"$MANIFEST")

if [ -x "$INSTALL_DIR/agy" ]; then
    CURRENT_VERSION=$("$INSTALL_DIR/agy" --version 2>/dev/null || true)
    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
        echo "Antigravity CLI is already up to date ($CURRENT_VERSION)."
        exit 0
    fi
    echo "Updating Antigravity CLI from $CURRENT_VERSION to $LATEST_VERSION..."
else
    echo "Installing Antigravity CLI $LATEST_VERSION..."
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
ARCHIVE_PATH="$TMP_DIR/antigravity.tar.gz"

curl -fL --retry 3 --output "$ARCHIVE_PATH" "$DOWNLOAD_URL"
ACTUAL_SHA512=$(sha512sum "$ARCHIVE_PATH" | awk '{print $1}')

if [ "$ACTUAL_SHA512" != "$EXPECTED_SHA512" ]; then
    echo "Error: Antigravity CLI checksum verification failed." >&2
    exit 1
fi

tar -xzf "$ARCHIVE_PATH" -C "$TMP_DIR"

if [ ! -f "$TMP_DIR/antigravity" ]; then
    echo "Error: The Antigravity CLI archive did not contain the expected binary." >&2
    exit 1
fi

install -Dm755 "$TMP_DIR/antigravity" "$INSTALL_DIR/agy"
INSTALLED_VERSION=$("$INSTALL_DIR/agy" --version)

if [ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]; then
    echo "Error: Installed Antigravity version ($INSTALLED_VERSION) does not match the server ($LATEST_VERSION)." >&2
    exit 1
fi

echo "Antigravity CLI $INSTALLED_VERSION installed at $INSTALL_DIR/agy."
