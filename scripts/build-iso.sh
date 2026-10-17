#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
[[ $EUID != 0 ]] || { echo "Run this wrapper as your normal user; it invokes sudo only for mkarchiso" >&2; exit 1; }
command -v mkarchiso >/dev/null || { echo "Install archiso explicitly first" >&2; exit 1; }
profile=$root/build/iso-profile
[[ -f "$profile/profiledef.sh" ]] || { echo "Run ./scripts/stage-iso.sh first" >&2; exit 1; }
[[ ! -e "$root/build/iso-work" ]] || { echo "Move/remove the previous build/iso-work before a fresh build" >&2; exit 1; }
mkdir -p "$root/dist"
sudo mkarchiso -v -w "$root/build/iso-work" -o "$root/dist" "$profile"
echo "ISO output: $root/dist (root-owned). Boot it using ./scripts/vm.sh run dist/<filename>.iso"
