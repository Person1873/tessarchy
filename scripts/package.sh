#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
[[ $EUID != 0 ]] || { echo "makepkg must run as a normal user" >&2; exit 1; }
mkdir -p "$root/dist"
tar -czf "$root/dist/tessarchy-0.1.0.tar.gz" -C "$root" shell session themes LICENSE
for package in tessera-shell tessarchy-session; do
    work=$root/build/packages/$package
    mkdir -p "$work"
    cp "$root/packaging/$package/PKGBUILD" "$root/dist/tessarchy-0.1.0.tar.gz" "$work/"
    (cd "$work"; PKGDEST="$root/dist" makepkg --force --cleanbuild --nodeps)
done
# This script neither installs packages nor resolves dependencies with sudo.
