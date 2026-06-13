#!/usr/bin/env python3
import sys
import re
import urllib.request
import json
import subprocess
import os

# Define project paths
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
YAZI_NIX_PATH = os.path.join(PROJECT_ROOT, "modules/core/shell/yazi.nix")

REPOS = {
    "llanosrocas/githead.yazi": {"hash_type": "sha256", "plugins": ["githead"]},
    "yazi-rs/plugins": {"hash_type": "hash", "plugins": ["full-border", "zoxide"]},
    "AnirudhG07/rich-preview.yazi": {"hash_type": "hash", "plugins": ["rich-preview"]},
    "ndtoan96/ouch.yazi": {"hash_type": "hash", "plugins": ["ouch"]},
    "Rolv-Apneseth/starship.yazi": {"hash_type": "hash", "plugins": ["starship"]},
    "boydaihungst/mediainfo.yazi": {"hash_type": "hash", "plugins": ["mediainfo"]}
}

def get_latest_commit(repo):
    url = f"https://api.github.com/repos/{repo}/commits/HEAD"
    req = urllib.request.Request(
        url,
        headers={"Accept": "application/vnd.github.v3+json", "User-Agent": "Nix-Plugin-Updater"}
    )
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode())
            return data["sha"]
    except Exception as e:
        print(f"Error fetching commit for {repo}: {e}", file=sys.stderr)
        return None

def fetch_sri_hash(repo, commit):
    tarball_url = f"https://github.com/{repo}/archive/{commit}.tar.gz"
    print(f"  Downloading and pre-fetching hash for {repo} ({commit[:7]})...")
    try:
        # Run nix-prefetch-url to get base32 SHA256
        res = subprocess.run(
            ["nix-prefetch-url", "--unpack", tarball_url],
            capture_output=True, text=True, check=True
        )
        base32_hash = res.stdout.strip()
        
        # Convert base32 to SRI hash
        res_sri = subprocess.run(
            ["nix", "hash", "to-sri", "--type", "sha256", base32_hash],
            capture_output=True, text=True, check=True
        )
        # Filter out warnings if any
        sri_hash = [line for line in res_sri.stdout.strip().split("\n") if line.startswith("sha256-")][0]
        return sri_hash
    except Exception as e:
        print(f"Error prefetching hash for {repo}: {e}", file=sys.stderr)
        return None

def main():
    if not os.path.exists(YAZI_NIX_PATH):
        print(f"Error: Yazi config file not found at {YAZI_NIX_PATH}", file=sys.stderr)
        sys.exit(1)

    with open(YAZI_NIX_PATH, "r") as f:
        content = f.read()

    updated = False

    for repo, info in REPOS.items():
        print(f"Checking {repo}...")
        latest_sha = get_latest_commit(repo)
        if not latest_sha:
            continue

        # Check current SHA for each associated plugin in yazi.nix
        for plugin in info["plugins"]:
            # Find the specific block for the plugin
            # Regex pattern to match plugin's fetchFromGitHub block
            pattern = rf'({plugin}\s*=\s*(?:\()?pkgs\.fetchFromGitHub\s*{{[^}}]+}})'
            match = re.search(pattern, content)
            if not match:
                print(f"  Could not find block for plugin '{plugin}' in yazi.nix", file=sys.stderr)
                continue

            block = match.group(1)
            
            # Extract current rev
            rev_match = re.search(r'rev\s*=\s*"([^"]+)";', block)
            if not rev_match:
                print(f"  Could not find current 'rev' in block for '{plugin}'", file=sys.stderr)
                continue

            current_sha = rev_match.group(1)
            if current_sha == latest_sha:
                print(f"  ✓ {plugin} is already up to date ({current_sha[:7]}).")
                continue

            print(f"  Updating {plugin}: {current_sha[:7]} -> {latest_sha[:7]}")
            
            # Fetch new SRI hash
            sri_hash = fetch_sri_hash(repo, latest_sha)
            if not sri_hash:
                print(f"  Failed to get SRI hash for {plugin}. Skipping.", file=sys.stderr)
                continue

            # Replace rev and hash in the specific block
            new_block = re.sub(r'rev\s*=\s*"[^"]+";', f'rev = "{latest_sha}";', block)
            
            hash_type = info["hash_type"]
            new_block = re.sub(rf'{hash_type}\s*=\s*"[^"]+";', f'{hash_type} = "{sri_hash}";', new_block)

            # Replace the old block with the new block in the file content
            content = content.replace(block, new_block)
            updated = True

    if updated:
        with open(YAZI_NIX_PATH, "w") as f:
            f.write(content)
        print("\n✓ Successfully updated yazi.nix with latest plugins!")
        print("Running git add...")
        subprocess.run(["git", "-C", PROJECT_ROOT, "add", YAZI_NIX_PATH])
        print("Done! You can run 'hms' to apply updates.")
    else:
        print("\n✓ All Yazi plugins are already at their latest versions!")

if __name__ == "__main__":
    main()
