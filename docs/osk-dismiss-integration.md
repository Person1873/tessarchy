# OSK dismissal integration checkpoint — 2026-10-22 UTC

Public integration branch: `sync/osk-dismiss-20261022` in the Person1873 fork.
Topic scope remains draft PR93 / issue89. This branch combines its implementation
with the existing public `sync/status-20261022` baseline and draft PR91's lift.
PR79's head is an ancestor. This branch is NOT the installed-device state.

The topic implementation and its software evidence remain separately reviewable
in `feat/osk-direct-dismiss`. No new native/GPU/VM/device acceptance is claimed.

## Merge resolution

- `docs/testing.md`: retained both append-only histories in FIFO order.
- `session/hyprland.lua`: retained the existing split-window helper/close handlers
  and added the lift helpers before `fit_dialog`; neither behavior was discarded.
- Shell entrypoint/qmldir merged automatically; existing status/taskbar work kept.

## Actual CPU-only verification

- Complete Qt suite:162 passed,0 failed, offscreen/software, scratch HOME/config.
- Workflow suite:71 passed. VM-related cases are command-plan fixtures, not VM boots.
- Lift policy:20 passed using Lua fixtures, including restore, minimum correction,
  reload recovery and external-move controls.
- Dismiss query/wiring:4 passed, real Lua interpreter with fixture layer objects.
- Integrated session Lua parsed with `luac -p`.

The topic's Qt button focus/draft test is included in the combined Qt suite.
This does not validate native no-focus layer semantics, delivered device touch,
real DBus dismissal/reopen, compositor layer coordinates or actual multi-output
acceptance. Those remain live gates. No personal app, session preference,
installed file, compositor/shell service, kernel device or package was changed.

## Continue

Live acceptance must be separately bounded: preserve installed bytes/preferences,
retain deployed differences, use only an owned disposable GTK text fixture and
its guarded input target, inspect full 48px button bounds in Phone/Tablet and
Desktop controls, verify delivered dismissal/draft/focus/reopen, then clean up.
Do not promote #80's earlier acceptance to evidence for this new feature. Native
fitting/scaling work and parked tasks remain parked.

AI-assisted implementation and verification.


## Native query transport correction — 2026-10-22 UTC

Merged the topic correction discovered during ASUS deployment: use `hyprctl
repl`, because eval returns only ok rather than captured JSON. Rechecked this
combined branch after the merge:162 Qt software results,71 workflow tests,
20 lift-policy tests and five query/wiring tests pass. Both append-only testing
records retained in the documentation merge conflict. Updated evidence hashes
match this branch. The combined branch is not a byte-for-byte device install;
see the separate sanitized ASUS deployment record for installed-path hashes and
actual mapped-layer/rendering checks. Delivered input/mode-matrix acceptance
still not established.
