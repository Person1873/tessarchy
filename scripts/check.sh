#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"
for script in scripts/*.sh session/start-tessarchy session/tessera-shell packaging/*/PKGBUILD; do bash -n "$script"; done
python -m unittest discover -s tests -v
if command -v luac >/dev/null; then luac -p session/hyprland.lua session/preferences.example.lua; else echo "SKIP: luac unavailable"; fi
if command -v desktop-file-validate >/dev/null; then
    # DesktopNames is valid for Wayland session entries; desktop-file-utils 0.28
    # still flags it. Tolerate only that quirk and fail on any other finding.
    validated=$(desktop-file-validate session/tessarchy.desktop 2>&1) || true
    serious=$(printf '%s\n' "$validated" | grep -viE 'key "DesktopNames"' || true)
    if [[ -n "$serious" ]]; then
        printf '%s\n' "$serious" 1>&2
        exit 1
    fi
else echo "SKIP: desktop-file-validate unavailable"; fi
if command -v Hyprland >/dev/null; then
    # Verification must not load the current user's preferences.
    scratch=$(mktemp -d)
    trap 'rm -rf -- "$scratch"' EXIT
    XDG_CONFIG_HOME="$scratch" Hyprland --verify-config -c "$root/session/hyprland.lua"
else echo "SKIP: Hyprland config parser unavailable"; fi
# Prefer the qmllint bundled with the installed Qt; a stray PATH entry can be
# an unrelated older binary that fails silently (seen as exit 255 with no output).
if [[ -x /usr/lib/qt6/bin/qmllint ]]; then lint=/usr/lib/qt6/bin/qmllint; else lint=$(command -v qmllint || true); fi
if [[ -n "$lint" ]] && command -v qs >/dev/null; then
    "$lint" -I /usr/lib/qt6/qml shell/shell.qml shell/components/TouchButton.qml
else echo "SKIP: qmllint/Quickshell unavailable"; fi
if command -v shellcheck >/dev/null; then
    shellcheck scripts/*.sh session/start-tessarchy session/tessera-shell
else echo "SKIP: shellcheck unavailable"; fi
echo "Available static/integration checks passed; GUI and ISO boot tests remain manual."
