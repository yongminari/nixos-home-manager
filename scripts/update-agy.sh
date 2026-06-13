#!/usr/bin/env bash
set -euo pipefail

# Find script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEV_TOOLS_PATH="$PROJECT_ROOT/modules/dev/dev-tools.nix"

echo "Checking for latest Antigravity CLI version..."
MANIFEST_AMD64=$(curl -fsSL "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_amd64.json" 2>/dev/null || true)
MANIFEST_ARM64=$(curl -fsSL "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/linux_arm64.json" 2>/dev/null || true)

if [ -z "$MANIFEST_AMD64" ] || [ -z "$MANIFEST_ARM64" ]; then
    echo "Error: Could not connect to the release server to check for updates." >&2
    exit 1
fi

# Extract versions and hashes
LATEST_VERSION=$(echo "$MANIFEST_AMD64" | python3 -c "import sys, json; print(json.load(sys.stdin)['version'])")
URL_AMD64=$(echo "$MANIFEST_AMD64" | python3 -c "import sys, json; print(json.load(sys.stdin)['url'])")
HEX_AMD64=$(echo "$MANIFEST_AMD64" | python3 -c "import sys, json; print(json.load(sys.stdin)['sha512'])")

URL_ARM64=$(echo "$MANIFEST_ARM64" | python3 -c "import sys, json; print(json.load(sys.stdin)['url'])")
HEX_ARM64=$(echo "$MANIFEST_ARM64" | python3 -c "import sys, json; print(json.load(sys.stdin)['sha512'])")

CURRENT_VERSION=$(grep -oP 'version\s*=\s*"\K[^"]+' "$DEV_TOOLS_PATH" || echo "")

if [ -z "$CURRENT_VERSION" ]; then
    echo "Error: Could not read current version from $DEV_TOOLS_PATH" >&2
    exit 1
fi

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "✓ Antigravity CLI is already at the latest version ($CURRENT_VERSION)."
    exit 0
fi

echo "Updating Antigravity CLI from $CURRENT_VERSION to $LATEST_VERSION..."

# Convert hex hashes to base64 SRI hashes
SRI_AMD64=$(python3 -c "import codecs, base64; print('sha512-' + base64.b64encode(codecs.decode('$HEX_AMD64', 'hex')).decode('utf-8'))")
SRI_ARM64=$(python3 -c "import codecs, base64; print('sha512-' + base64.b64encode(codecs.decode('$HEX_ARM64', 'hex')).decode('utf-8'))")

python3 - <<EOF
with open("$DEV_TOOLS_PATH", "r") as f:
    content = f.read()

import re

# Replace version
content = re.sub(r'version\s*=\s*"[^"]+";', f'version = "{LATEST_VERSION}";', content)

# Replace hashes
content = re.sub(
    r'x86_64-linux\s*=\s*"sha512-[^"]+";',
    f'x86_64-linux = "{SRI_AMD64}";',
    content
)
content = re.sub(
    r'aarch64-linux\s*=\s*"sha512-[^"]+";',
    f'aarch64-linux = "{SRI_ARM64}";',
    content
)

# Replace urls
content = re.sub(
    r'x86_64-linux\s*=\s*"https://storage\.googleapis\.com/[^"]+";',
    f'x86_64-linux = "{URL_AMD64}";',
    content
)
content = re.sub(
    r'aarch64-linux\s*=\s*"https://storage\.googleapis\.com/[^"]+";',
    f'aarch64-linux = "{URL_ARM64}";',
    content
)

with open("$DEV_TOOLS_PATH", "w") as f:
    f.write(content)
EOF

echo "✓ Successfully updated $DEV_TOOLS_PATH to version $LATEST_VERSION!"
echo "Running git add..."
git -C "$PROJECT_ROOT" add "$DEV_TOOLS_PATH"
echo "Done! You can now run 'hms' to apply the update."
