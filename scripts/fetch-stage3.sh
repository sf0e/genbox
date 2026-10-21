#!/bin/bash
# Download a Gentoo stage3 tarball.
# Usage: fetch-stage3.sh <url> <destination>
set -euo pipefail

url="$1"
dest="$2"

mkdir -p "$(dirname "$dest")"

if [ -s "$dest" ]; then
    echo "==> stage3 already present: $dest"
    exit 0
fi

echo "==> downloading stage3"
echo "    $url"
if command -v wget >/dev/null 2>&1; then
    wget -O "$dest.part" "$url"
elif command -v curl >/dev/null 2>&1; then
    curl -L -o "$dest.part" "$url"
else
    echo "error: need wget or curl" >&2
    exit 1
fi

mv "$dest.part" "$dest"
echo "==> saved $dest"
