#!/usr/bin/env bash
# Build the pinned optional title-bar plugin with the installed toolchain.
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
for tool in git make pkg-config; do
    command -v "$tool" >/dev/null || { echo "Missing build tool: $tool" >&2; exit 1; }
done
[[ $(pkg-config --modversion hyprland) == 0.56.2 ]] || {
    echo "This plugin pin requires Hyprland 0.56.2 headers." >&2; exit 1
}
mkdir -p -- "$root/build" "$root/dist"
scratch=$(mktemp -d "$root/build/window-bars.XXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
git clone --filter=blob:none --no-checkout https://github.com/hyprwm/hyprland-plugins.git "$scratch/source"
git -C "$scratch/source" checkout --detach 7644cecdb947060682891a0db2a0cdc5c0b9e704
git -C "$scratch/source" apply "$root/patches/hyprbars-touch.patch"
make -C "$scratch/source/hyprbars"
install -m644 -- "$scratch/source/hyprbars/hyprbars.so" "$root/dist/hyprbars-0.56.2.so"
echo "Built dist/hyprbars-0.56.2.so; load only with the matching Hyprland build."
