#!/usr/bin/env bash
# Build the Tessarchy packages and the pacman repository that installed machines
# update from.
#
#   ./scripts/build-packages.sh [output-dir]      # default: dist/repo/x86_64
#
# Output layout (served as static files, so the project website can host it):
#
#   dist/repo/x86_64/tessarchy.db.tar.gz        the package database
#   dist/repo/x86_64/tessarchy.db               symlink pacman follows
#   dist/repo/x86_64/*.pkg.tar.zst              the packages themselves
#   dist/repo/x86_64/repo-info.json             version summary for --check
#
# Installed machines read repo-info.json (a few hundred bytes) to answer "is
# there anything newer?" without syncing a database or needing privileges, then
# hand the actual install to pacman.
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
arch=${TESSARCHY_ARCH:-x86_64}
version=${TESSARCHY_VERSION:-0.1.0}
output=${1:-$root/dist/repo/$arch}
commit=${GITHUB_SHA:-$(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo unknown)}
built=$(date -u +%Y-%m-%dT%H:%M:%SZ)

for tool in makepkg repo-add bsdtar python3; do
    command -v "$tool" >/dev/null || { echo "Missing build tool: $tool" >&2; exit 1; }
done
[[ $EUID != 0 ]] || { echo "makepkg must run as a normal user" >&2; exit 1; }

"$root/scripts/package.sh"

mkdir -p "$output"
rm -f "$output"/*.pkg.tar.zst "$output"/tessarchy.db* "$output"/repo-info.json
cp "$root"/dist/*.pkg.tar.zst "$output/"

# repo-add writes tessarchy.db.tar.gz plus the tessarchy.db symlink pacman
# actually looks for; copying the packages in first keeps them both in sync.
repo-add --new --nocolor --quiet "$output/tessarchy.db.tar.gz" "$output"/*.pkg.tar.zst

# The package metadata is read straight out of the archives (.PKGINFO), so this
# does not depend on pacman being able to read a foreign database.
python3 - "$output" "$version" "$arch" "$commit" "$built" <<'PY'
import json
import subprocess
import sys
import tarfile
from pathlib import Path

output, version, arch, commit, built = sys.argv[1:6]
packages = {}
for archive in sorted(Path(output).glob("*.pkg.tar.zst")):
    if archive.name.endswith(".sig"):
        continue
    listing = subprocess.run(["bsdtar", "-tf", str(archive)], capture_output=True,
                             text=True, check=True).stdout.split()
    member = next(name for name in listing if name.endswith(".PKGINFO"))
    raw = subprocess.run(["bsdtar", "-xOf", str(archive), member], capture_output=True,
                         text=True, check=True).stdout
    fields = {}
    for line in raw.splitlines():
        if "=" in line and not line.startswith("#"):
            key, _, value = line.partition("=")
            fields.setdefault(key.strip(), value.strip())
    packages[fields.get("pkgname", archive.name)] = {
        "version": fields.get("pkgver", "?"),
        "file": archive.name,
        "description": fields.get("pkgdesc", ""),
    }

info = {
    "version": version,
    "architecture": arch,
    "commit": commit,
    "built": built,
    "packages": packages,
}
Path(output, "repo-info.json").write_text(json.dumps(info, indent=2, sort_keys=True) + "\n")
print(f"repo-info.json: {version} ({commit}) with {len(packages)} packages")
PY

ls -l "$output"
echo "repository ready: $output"
