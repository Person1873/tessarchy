#!/usr/bin/env bash
# User-only login hook; preserves the profile outside our marked block.
set -euo pipefail
operation=${1:-}
case "$operation" in enable|disable) ;; *) echo "Usage: $0 enable|disable" >&2; exit 2;; esac
command -v python >/dev/null || { echo "Python 3 required" >&2; exit 1; }
if [[ $operation == enable && ! -x $HOME/.local/bin/start-tessarchy ]]; then
    echo "Install the development session first" >&2; exit 1
fi
python - "$operation" <<'PYTHON'
from pathlib import Path
import shutil
import sys
import time

profile = Path.home() / '.bash_profile'
if profile.is_symlink():
    raise SystemExit('Refusing a symlinked .bash_profile')
original = profile.read_bytes() if profile.exists() else b''
begin = b'# BEGIN TESSARCHY LOGIN\n'
end = b'# END TESSARCHY LOGIN\n'
block = begin + b'''if [[ -z ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} && $(tty) == /dev/tty1 ]]; then
    "$HOME/.local/bin/start-tessarchy"
fi
''' + end
if begin in original or end in original:
    if original.count(begin) != 1 or original.count(end) != 1 or block not in original:
        raise SystemExit('Login block was modified or malformed; preserve and edit it manually')
    if sys.argv[1] == 'enable':
        print('Tessarchy login startup already enabled')
        raise SystemExit(0)
    changed = original.replace(block, b'', 1)
else:
    if sys.argv[1] == 'disable':
        print('Tessarchy login startup already disabled')
        raise SystemExit(0)
    changed = original + (b'\n' if original and not original.endswith(b'\n') else b'') + block
if profile.exists():
    backup = profile.with_name('.bash_profile.tessarchy-backup-' + str(time.time_ns()))
    shutil.copy2(profile, backup)
    print('Profile backup:', backup)
profile.write_bytes(changed)
print('Tessarchy tty1 login startup', 'enabled' if sys.argv[1] == 'enable' else 'disabled')
PYTHON
