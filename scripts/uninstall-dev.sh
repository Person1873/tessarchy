#!/usr/bin/env bash
set -euo pipefail
data=${XDG_DATA_HOME:-$HOME/.local/share}/tessarchy
[[ -f "$data/.tessarchy-dev-install" && ! -L "$data" ]] || {
    echo "No marked Tessarchy development installation at $data" >&2; exit 1;
}
version=$(cat "$data/.tessarchy-dev-install")
[[ "$version" == tessarchy-dev-v1 || "$version" == tessarchy-dev-v2 ]] || exit 1
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# Preserve launchers edited since installation; report instead of deleting them.
for launcher in start-tessarchy tessera-shell; do
    target=$HOME/.local/bin/$launcher
    if [[ -e "$target" || -L "$target" ]]; then
        cmp -s -- "$root/session/$launcher" "$target" || {
            echo "Modified launcher: $target; preserve or remove it manually before uninstalling" >&2; exit 1;
        }
    fi
done
rm -f -- "$HOME/.local/bin/start-tessarchy" "$HOME/.local/bin/tessera-shell"
# Remove only installed files, never user preferences or unrelated files.
manifest=$data/.tessarchy-dev-files
if [[ "$version" == tessarchy-dev-v2 && -f "$manifest" ]]; then
    # Deepest first so files are removed before their directories.
    while IFS= read -r relative; do
        if [[ -e "$data/$relative" || -L "$data/$relative" ]]; then
            rm -f -- "$data/$relative"
        fi
    done < <(sort -r -- "$manifest")
    rm -f -- "$manifest"
else
    # Legacy v1: the fixed set present when that version was current.
    rm -f -- "$data/shell/shell.qml" "$data/shell/components/TouchButton.qml" "$data/session/hyprland.lua" "$data/.tessarchy-dev-install"
fi
find "$data" -depth -type d -exec rmdir -- {} \; 2>/dev/null || true
echo "Development copy removed. ~/.config/tessarchy preferences retained."
