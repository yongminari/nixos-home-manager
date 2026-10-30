#!/usr/bin/env bash
set -euo pipefail

target=${1:?Expected target path}
defaults=${2:?Expected default configuration}
mkdir -p "$(dirname "$target")"
# Keep the user's existing toggle state, including on repeated activation.
if [[ ! -e "$target" ]]; then
    cp --no-clobber "$defaults" "$target"
    chmod u+w "$target"
fi
