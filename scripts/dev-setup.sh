#!/bin/bash
# Set up local development environment
# Symlinks sibling repos for local dev instead of pulling from registry

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
REPOS_DIR="$(dirname "$ROOT_DIR")"

mkdir -p "$ROOT_DIR/.dev"

# Link provider repos if they exist
for repo in quicue-proxmox quicue-docker quicue-incus quicue-k3d quicue-vcf quicue-infra; do
    name="${repo#quicue-}"
    if [ -d "$REPOS_DIR/$repo" ]; then
        ln -sf "$REPOS_DIR/$repo" "$ROOT_DIR/.dev/$name"
        echo "Linked: .dev/$name -> $REPOS_DIR/$repo"
    fi
done

echo ""
echo "Dev environment ready. Symlinks in .dev/:"
ls -la "$ROOT_DIR/.dev/" | grep "^l"
