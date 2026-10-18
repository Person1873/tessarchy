# Tessarchy handoff for Hermes or another model

Last checkpoint: 2026-10-17 local / 2026-10-18 UTC, agent guide and fresh layout captures. This file is the
persistent continuation record requested by Charles. Keep it in the Tessarchy
folder and update it after each meaningful merge, validation, or blocker.
Never include passwords, tokens, SSH private keys, or other credentials.

## Current user request — completed

- Root agent README with shared planning register and 56 actionable tasks:
  https://github.com/thediamondsaint/tessarchy/blob/main/AGENT-README.md
- Direct documentation and the owner's writing preference saved in AGENTS.md,
  AGENT-README.md and this handoff.
- Fresh current-source tablet/desktop home and quick-controls captures published
  on the website; the screenshot ZIP contains thirteen original images.

PR #27 merged as 3f512bc9ed76388ee82611f1654a914896700a4a after Ubuntu/Arch and
Pages checks passed. The public assets were checked against their local hashes.
Prior login, branding, roadmap and showcase work (#25/#26) is also complete.
The 12 deferred contributor PRs and #9's unfinished worktree are preserved.

Historical sections retain earlier checkpoints. The final dated checkpoint
supersedes old next-action statements.

## Communication and working rules

- Use standard technical English in code and responses. Keep comments to one line.
- Owner preference: direct documentation; state capabilities, instructions and
  validation once, without repetitive caveats or speculative disclaimers.
- Be concise and direct. Continue authorized work without routine confirmation.
- Give meaningful progress updates at least once per minute during active work.
- Follow the root AGENTS.md. Do not modify the host’s Hyprland/Omarchy settings.
- Do not install dependencies automatically on the host or development guest.
- Run ./scripts/check.sh; use scratch HOME for installer/uninstaller tests.
- Keep touch targets at least 48 logical pixels, preserve app keyboard focus in
  navigation, and confirm window close and session exit.
- Owner decision in this session: on-screen keyboard keys may be narrower than
  48 logical pixels but must remain at least 48 pixels tall. Other touch targets
  remain >=48 in both dimensions. This explicitly resolves the #11/#20 width
  exception; it is no longer a blocker.
- No secure locking claims. Separate actual results from pending/manual tests
  in docs/testing.md. Do not claim an ISO boots without inspecting a VM boot.
- Never commit disk images or credentials. Generated files belong under ignored
  build/, dist/, or vm/. No force pushes, history rewriting, or broad deletion.
- No subagents unless explicitly authorized by the user or applicable instructions.

## Repository and public services

- Working directory: /home/charles/Work/tessarchy
- Repository: https://github.com/thediamondsaint/tessarchy
- Website: https://thediamondsaint.github.io/tessarchy/
- Main development areas: shell/ (Quickshell/QML), session/ (Hyprland Lua and
  helpers), tests/, assets/, packaging/, iso/ (live image overlay).
- API targets: Hyprland 0.56 Lua and Quickshell 0.3.1. Inspect installed QML type
  metadata and run Hyprland --verify-config when changing those APIs.
- Host has Quickshell 0.3.1 and Hyprland 0.56.2-2; the development guest and
  current live image have Quickshell 0.3.2-1 and Hyprland 0.56.2-4.
- GitHub CLI is authenticated as the repository owner. Do not print credentials.

## Worktrees and branch state

1. Repository root: active branch feat/phone-login (branched from build/live-iso). It now includes main through merged
   PRs #14/#15/#17, plus this handoff and the effort ranking. It is the website/development activity branch;
   historical Alpha 2 source remains available by its original commit/tag.
2. build/publish: branch feat/phone-shell. It was synchronized to the tested
   Alpha 2 tree with merge commit e71ae0e and pushed. That synchronization was
   used to complete PR #1.
3. build/integration: DEFERRED branch review/pr-9-fix, with an UNCOMMITTED MERGE of
   review/pr-7-fix into original #9. Preserve this work; do not reset or abort.
   Local checks passed after the latest Icon/theme changes (33 Python, 21 Qt).
   Final theme runtime review and commit/push are still pending.
4. build/bluetooth: branch review/pr-24-fix, head
   eb77f7c64d7cde4076270000fa7f928fe20f2cf2, pushed to contributor
   kriscrossapplesauce2004/tessarchy:feat/bluetooth. PR #24 is merged; this worktree is clean.
5. origin/main includes merged PRs #1 through #8, #14, #15, #17 and #24. PR #7 main merge is
   bd34e999b43f7aaf067a26db18949544ee6f531d; #8 main merge is
   86699aec2002fba415b8a539dde06ba04943e695. Fetch before relying on the tip.
6. build/quick-prs: branch review/pr-14-fix, clean reviewed screenshot head
   c91b9eef6e9f3082eea81f89ff90373be3de711c, pushed to fork feat/screenshots.
   Fixed #15/#17 heads remain in review/pr-15-fix and review/pr-17-fix.
7. Original PR heads remain under refs/remotes/review/pr-N. Fixed local
   review/pr-N-fix branches preserve contributor history with merge commits.

Useful commands:

```bash
git status --short
git worktree list
git fetch origin
gh pr list --state open --limit 100
gh pr view NUMBER --json headRefOid,mergeable,isDraft,statusCheckRollup
```

Use full 40-character commit IDs with gh pr merge --match-head-commit; short
IDs are rejected. Preserve contributor commit ancestry using merge commits.
The fork PRs have maintainerCanModify=true, and owner pushes to their head
branches have succeeded without force. Never assume this for another repo.

## Completed pull-request work in this session

### PR #1 — merged

The Quiet Edge/phone-shell baseline was synchronized with the latest tested
Alpha 2 tree, marked ready, and merged into main. Merge commit on main:
f774564 (fetch for full ID). No contributor features were dropped.

### PR #2 — merged

Contributor: kriscrossapplesauce2004, fork branch hardening-and-apps.
Original head f42526b; integrated head c778aef (fetch for full ID).

Included manifest-based installation/uninstallation, new refusal-path tests,
TryExec, desktop-file validation and an application drawer from DesktopEntries.
The drawer was ported into the current glass AppTile launcher, retaining native
app icons, elided labels, current Settings/Controls tiles and correct panel size.

Defect fixed during review: the original manifest uninstaller accepted traversal
and symlink-parent paths that could delete outside the installation. The fixed
version validates the entire manifest before removing launchers/files, rejects
unsafe entries, preserves extras, and retains the legacy v1 cleanup path.
A regression test verifies refusal before any removal.

CI initially failed on Ubuntu because refusal tests assumed the system Arch
signing keyring. The fetcher now accepts ARCH_ISO_KEYRING for an explicitly
provisioned trusted keyring, preserving mandatory signature verification.
Tests use a scratch keyring fixture and never reach signature verification or
accept a downloaded image. CONTRIBUTING.md documents the option.

Validation: ./scripts/check.sh passed 26 Python tests, 19 Qt Quick results,
Lua syntax, Hyprland parser and QML lint. Scratch-HOME safety tests passed.
The development VM rendered real app entries/icons and successfully launched
Foot from the drawer. CI ISO build run 39065086205 passed before merging.
Known PanelWindow metadata warnings remain; ShellCheck is unavailable locally.

### PR #3 — merged

Contributor: kriscrossapplesauce2004, fork branch feat/desktop-mode.
Integrated local branch review/pr-3-fix, pushed head 5af78a4.
Adds workspace strip, focused title, keyboard focus/move/drag/resize/volume binds.

Review fixes:
- Desktop override on a phone must not crowd the top strip; workspace buttons
  show only on >=900px desktop/tablet outputs. Slot count is bounded through 8.
- Super+Q and Super+Shift+E now invoke shell actions closeWindow/endSession,
  which open confirmation pages. They do not directly close/exit.
- Quickshell.activeToplevel can initially be null after a shell restart despite
  a focused Foot window. root.activeWindow falls back to the activated native
  Wayland handle. The focused title uses the same fallback.
- Current glass layout, pull-down modes and card switcher were retained.

Validation: 26 Python tests and 21 Qt Quick results passed, along with Lua,
Hyprland parser and QML lint. Installed Hyprland workspace/monitor/toplevel
metadata was inspected. In the VM, 1280x800 desktop workspace buttons and title
rendered; tapping workspace 2 changed activeworkspace to 2. The close action
opened confirmation without closing Foot. The exit action was invoked for
inspection; do not confirm it during validation unless deliberately ending VM UI.
CI ISO build 39065662379 passed; PR #3 is merged. Session-exit confirmation
was visually inspected and canceled, and native 400x800 portrait was restored.

## Current immediate next actions

The requested documentation and image work is complete. For the next product
assignment, claim a task in AGENT-README.md and inspect current Git/VM state.
The recommended starting work is T01–T03: real media/audio and screenshot action
acceptance. Keep #9's preserved worktree intact.

## Pending PR inventory and dependency cautions

All contributor PRs were retargeted from feat/phone-shell to main after #1
merged, as their descriptions requested. Their heads were preserved except
for the reviewed integration updates described here.

- #1: Add Quiet Edge mobile shell, card switching and pull-down controls. Merged. Original state: draft.
- #2: Harden install tooling and fill the app drawer from desktop entries. Merged. Original state: open.
- #3: Add a desktop workspace strip, focused-window title and desktop keybindings. Merged. Original state: open.
- #4: Bundle fish as the live user's login shell. Merged. Original state: open.
- #5: Harden the live rootfs identity and runtime defaults. Merged. Original state: open.
- #6: Make the source checks portable and add a checks workflow. Merged. Original state: open.
- #7: Integrate squeekboard as an optional on-screen keyboard. Merged. Original state: draft.
- #8: Keep Phone/Tablet apps maximized and fit oversized dialogs. Merged. Original state: draft.
- #9: Carry the system theme through shell, keyboard and apps (Omarchy themes). Review pending. Original state: draft.
- #10: Touch file dialogs on Phone/Tablet (portal backend + GTK3 module). Review pending. Original state: draft.
- #11: On-screen keyboard rows fit 48 logical px. Review pending. Original state: draft.
- #12: Tablet split: two apps side by side with touch controls. Review pending. Original state: draft.
- #13: Add notification pop-ups and an alert center. Review pending. Original state: open.
- #14: Add full-screen screenshots from Quick controls and the Print key. Merged in this effort-ordered pass. Original state: open.
- #15: Add MPRIS media controls to the status bar and Quick controls. Merged in this effort-ordered pass. Original state: open.
- #16: Show live window previews in the app switcher. Review pending. Original state: open.
- #17: Add a PipeWire audio panel to quick controls. Merged in this effort-ordered pass. Original state: open.
- #18: Add a battery and power-mode panel to quick controls. Review pending. Original state: open.
- #19: Add display controls: brightness helper, keys and a night-light toggle. Review pending. Original state: open.
- #20: Keep the keyboard hidden while a shell page is open. Review pending. Original state: draft.
- #21: Blank the idle panel after five minutes with hypridle. Review pending. Original state: open.
- #22: Rotate the focused display from Settings in 90° steps. Review pending. Original state: open.
- #23: Connect Wi-Fi from Quick controls through NetworkManager. Review pending. Original state: open.
- #24: Add Bluetooth quick controls to the shell. Merged; source and ISO CI passed. Original state: open.

Important relationships:
- #9 includes #7 (OSK); #10 includes #9/#7; #11 includes #10/#9/#7;
  #20 includes that full chain. Review incremental commits, not all inherited
  changes repeatedly. Preserve DAG ancestry so GitHub recognizes actual merges.
- #12 includes #8 and several older Recents rewrites. Preserve the current
  iPhone-style horizontal glass AppSwitcher; integrate split behavior into it.
  The user explicitly rejected headings such as “Recent App” and text actions
  such as “Return to App”/“Close”; those remain glass icon buttons.
  Swipe-to-close must still confirm before closing, per AGENTS.md.
- #16’s old grid preview implementation overlaps the already working native
  previews in AppSwitcher. Do not regress to the old grid to make it merge.
- #13’s uninstaller tree mirror conflicts with the safer manifest implementation
  from #2. Retain the manifest safety behavior while including notification files.
- #17/#18/#19/#23/#24 all insert into the removed bottom status page. Integrate
  them into QuickSettings/pull-down components instead. Keep controls usable on
  400x800, scrolling as necessary; no fake hardware states.
- #22 rotation contains a known FINAL property collision fix already in its
  branch. More importantly, runtime testing during #3 revealed that
  `hyprctl keyword monitor ...` FAILS on the current Lua parser with
  “keyword can't work with non-legacy parsers. Use eval.” The PR’s current
  rotation implementation uses keyword and must be fixed before merging.
  Runtime `hyprctl eval 'hl.monitor({...})'` works in this VM. Preserve mode,
  scale, position and touch mapping; use validated data and safe argument arrays.
- PRs #11/#20 modify AGENTS.md for keyboard sizing. The owner explicitly
  approved narrower keys in the active conversation, retaining >=48px height.
  Preserve that actual ruling and the >=48px rule for other controls.
- Draft status is not proof of readiness. Inspect, test, fix, then mark ready
  when appropriate. Do not call untested hardware behavior verified.

## Source review files and logs

Ignored files in build/pr-review/:
- N.json: full PR metadata/body/files/commit list captured before review.
- pr2-check.log, pr2-ci-failure.log, pr3-check.log.
- pr2-launcher.png: actual development VM app drawer.
- pr2-clients.json: actual clients after launching Foot.
- pr3-confirm.png: actual close confirmation.
- pr3-desktop.png: workspace strip/title at 1280x800.
- pr3-workspace.json: active workspace changed to 2 (has an “ok” prefix).
- launcher-shell.tar, desktop-shell.tar: exported candidate shell files.
Original PR metadata: build/pr-review-current.json.
Temporary resolve scripts /tmp/tessarchy-pr2-resolve.py and
/tmp/tessarchy-pr3-resolve.py were one-off helpers; inspect before reuse.

## Development VM and safe interaction

- Existing QEMU/KVM disk: vm/Arch-Linux-x86_64-basic.qcow2, 2 GiB RAM, 2 vCPUs.
- SSH endpoint: arch@127.0.0.1 port 2222, active ControlMaster socket
  vm/ssh-control in the root worktree. Credentials are intentionally omitted.
- Do not start another VM on the same disk while it is running.
- Guest shell: ~/.local/share/tessarchy/shell; compositor config:
  ~/.local/share/tessarchy/session/hyprland.lua.
- Backup of the pre-review installed source:
  ~/tessarchy-backups/pr-review-alpha2. Do not overwrite this backup.
- Guest current installed candidate includes PR #3, even while #4 is being
  prepared in the local worktree. Do not confuse it with committed main.
- Foot launched for the PR #2 test: PID 3959, address 0x55f018e45140 (may change).
- Preserve user preferences: 12-hour clock, reduced motion, automatic layout.
- Native portrait mode is 400x800, transform=0. Runtime desktop test is 1280x800.
- Guest has no physical radios, no UPower service and no active audio service;
  unavailable states must remain honest. Do not install daemons automatically.

Guest command environment:

```bash
export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus LANG=C.UTF-8
export HYPRLAND_INSTANCE_SIGNATURE=$(basename /run/user/1000/hypr/*)
```

SSH example from the repository root:

```bash
ssh -S vm/ssh-control -p 2222 arch@127.0.0.1 '...'
scp -o ControlPath=vm/ssh-control -P 2222 source-file arch@127.0.0.1:/tmp/file
```

A tar extraction replaces watched QML inodes and may leave Quickshell on stale
source. Restart only Tessera after deploying a candidate, with the environment
above. Kill and start in separate calls; starting immediately can see the dying
instance and silently refuse. Do not kill Hyprland.

```bash
qs kill -p ~/.local/share/tessarchy/shell/shell.qml
# In a subsequent call, with the same runtime environment:
~/.local/bin/tessera-shell -d
```

The last valid Quickshell instance was r43khi2nt, PID 4059, but deployment/hot
reload can change these. Logs:
`qs log -p ~/.local/share/tessarchy/shell/shell.qml -t 40 --no-color`.

Temporary debug diagnostics were added to the guest actions IPC while testing
active-window lookup, then removed by redeploying the real shell/shell.qml.
Do not reintroduce the diagnostics into committed production source.

Runtime resize examples (inside the guest environment):

```bash
hyprctl eval 'hl.monitor({output="Virtual-1",mode="1280x800@60",position="auto",scale=1,transform=0})'
hyprctl eval 'hl.monitor({output="Virtual-1",mode="400x800@60",position="auto",scale=1,transform=0})'
```

Guest test helpers:
- /tmp/grim captures the real Wayland display; copied binary, no package install.
- `sudo -n python /tmp/guest-input.py X Y` clicks a coordinate; optional final
  signed count sends wheel events. This uses a guest-only uinput device.
- /tmp/keys.py is an older key injector; inspect before using.
- /tmp/shade-swipe.py down|up tests the pull-down gesture.

## Existing implemented interface to preserve

- Quiet Edge frosted top strip and floating glass bottom navigation.
- Compact mobile clock, pull-down radio/volume controls and Auto/Phone/Tablet/
  Desktop mode selector. The home-screen “Auto Phone Change” button is removed.
- Horizontal iPhone-style AppSwitcher with real ScreencopyView previews,
  DesktopEntry icons, glass icon actions, dots, keyboard Alt+Tab and confirmed
  close. Selection must remain a window reference across layout resizes.
- Active app activation is deferred 100ms until the switcher keyboard grab is
  released. Alt release Lua bindings use keycodes 64/108, not Alt_L/Alt_R.
- Automatic layout: shortest edge <600 => Phone; else width>=1100 and height>=650
  => Desktop; otherwise Tablet. Saved manual overrides remain available.
- Finite 1.6s six-face cube logo animation, no idle loop; reduced motion settles.
- Real radio power helper uses rfkill JSON, validates arguments/permissions,
  re-reads state after writes/failure, and never escalates privileges. Airplane
  off unblocks all radios, not a restoration of prior individual selections.
- No network selection, Bluetooth pairing, calls, SMS or real signal strength
  are claimed until the corresponding reviewed integrations actually work.

## Published ISO and release facts

Latest public release: v0.1.0-alpha.2.
https://github.com/thediamondsaint/tessarchy/releases/tag/v0.1.0-alpha.2

ISO asset: tessarchy-0.1.0-20261017-x86_64.iso, 1,070,628,864 bytes.
SHA-256: 3bc2565684d9a2a1de62946f6f7d59117dafc71abf75d226be14b5214d9209ee
Built from aa8b59a73a8d5d6b1d3fab6c17272e68e0bfac58 by Actions 39063437439,
archiso 91-1. BIOS and non-Secure-Boot UEFI graphical home screens were visually
inspected in diskless QEMU/KVM, 2 GiB RAM, 2 vCPUs, virtio graphics, no NIC.
The downloaded full ISO checksum also matched locally and the release digest.
Local verified image and supporting text files are in ignored dist/alpha2/.

Alpha 2 includes the pre-integration Quiet Edge/card/pull-down interface.
Newly merged contributor changes are NOT in that already-published ISO.
Do not replace its image or alter its tag to pretend otherwise. A later tester
release needs a new source commit/build, checksum and inspected boot captures.
Alpha 1 also exists and shares the same date-based filename; distinguish by tag
and checksum. Neither image is an installer or persistent system. Physical
hardware, touch, radio behavior, Secure Boot, and full app acceptance remain
separate from graphical boot smoke tests.

Build workflow: .github/workflows/build-iso.yml. A manual dispatch with a new
release_tag builds in a privileged disposable CI container, verifies checksum,
collects BIOS/UEFI captures and creates a DRAFT prerelease. Inspect captures
before publishing. No host privileged build or dependency installation is needed.
Scripts refuse overwrite of staging/work paths; do not broadly remove build dirs
or leftover mounts. Existing user ISO-build authorization does not justify
changing host configuration or installing packages automatically.

## Website and deployment

Static site source is website/{index.html,style.css,app.js}.
Build: `python scripts/build-site.py --output NEW_PATH --releases JSON_FILE`.
The output path must not exist. It bundles seven actual VM screenshots and their
original-byte ZIP, current commit provenance and public release metadata.
No secrets, tracking scripts or external fonts are needed.

Pages workflow deploys main and build/live-iso changes, and release events.
The GitHub Pages environment permits the two branches and v* release tags.
The version-tag rule was added after an Alpha 2 release-triggered job was
rejected; rerun 39063878257 then passed. Final pre-PR site deployment
39064382954 passed from 8c67414, with public metadata/links/ZIP bytes verified.
Merging PRs into main also triggers Pages; monitor which source is deployed.
The website’s JS currently reads commit activity from build/live-iso, so at the
end synchronize that branch with main (without discarding either history), or
intentionally change the site’s tracked branch and document the choice.
Keep release descriptions distinct from newly merged development features.

## End-of-integration checklist

- Every merge is reviewed, conflict-resolved and appropriately checked.
- Existing UI requirements, >=48px targets, focus and confirmations preserved.
- No accidental AGENTS.md relaxation or unreviewed privilege escalation.
- Source checks pass on the integrated main tree; inspect QML runtime logs.
- Exercise new available controls in the VM, and clearly label hardware-only
  tests as pending. Do not fake successful Wi-Fi/Bluetooth/battery/backlight.
- Synchronize the development/publishing branch and update README, architecture,
  roadmap, docs/testing.md and GitHub review inventory to reflect actual merges.
- Keep the published Alpha 2 provenance intact. If a new ISO is built, use a new
  prerelease tag and inspect actual BIOS/UEFI boot images before publication.
- Update the website with accurate feature/release information and real captures.
- Confirm remote PR status and clean worktrees; do not delete contributors’ branches.
- Update this handoff with final commit IDs, remaining blockers and exact next step.

## Historical checkpoint after initial integrations

- #1, #2, #3 merged. #3 source head 5af78a4, ISO CI 39065662379 succeeded.
- #4 reviewed and pushed as c5b4a1e on contributor feat/bundle-fish; CI pending.
- #5 declarative rootfs changes reviewed; docs conflict resolved, checks running.
- Guest close and exit confirmations inspected; exit canceled; portrait restored.
- HANDOFF.md first committed/pushed as 5b76b90 on build/live-iso.

## Historical owner keyboard decision and CI checkpoint

- The owner answered: “Allow narrower keys; keep key height at least 48 pixels.”
  AGENTS.md now records the exception explicitly. No further approval is needed.
- PRs #1 through #6 are merged. #6 fixed head 37bf982 passed Ubuntu source
  checks, Arch full-toolchain checks (including fish and ShellCheck), and ISO CI.
- Active integration worktree is review/pr-8-fix, merging review/pr-6-fix.
  README/roadmap/testing conflicts resolved; a Lua test stub needed to accept
  nil arguments when constructing mouse-resize bindings. Checks are rerunning.
- Next: finish #8 runtime activation/dialog checks, then #7 keyboard and its
  dependent #9/#10/#11/#20 chain. All remaining independent PRs still need review.

## Bluetooth #24 review checkpoint, 2026-10-17

The owner explicitly prioritized #24, then requested the handoff update and a
shareable commit link. Finish this scoped task before resuming other PR work.

Reviewed source head: eb77f7c64d7cde4076270000fa7f928fe20f2cf2.
https://github.com/kriscrossapplesauce2004/tessarchy/commit/eb77f7c64d7cde4076270000fa7f928fe20f2cf2
PR: https://github.com/thediamondsaint/tessarchy/pull/24

Changes:
- Merged current main into the contributor branch without rewriting history.
- Ported BluetoothPanel into current QuickSettings as an expandable glass
  device section. Retained existing rfkill power tile and current AppSwitcher.
  Did not add a misleading top-bar connected indicator for adapter power alone.
- Discovery starts only while expanded and powered on, stops on hide, adapter
  replacement or power-off, and does not stop pre-existing discovery that this
  panel did not request. This is local request tracking, not a global D-Bus lock.
- Guarded actions against missing/stale devices, transitional states, blocked
  devices and unpaired connect requests; keyboard tab focus on new controls.
- Device labels render plain text. Invalid battery readings stay unavailable.
- Existing safe manifest installer/uninstaller retained; no hard-coded legacy
  uninstall changes needed because the new component is covered by the manifest.
- Pairing/passkey agents, forgetting and multiple-adapter selection are outside
  this implementation. Use an external Bluetooth manager for pairing.

Actual validation:
- ./scripts/check.sh: 31 Python and 22 Qt Quick checks passed, plus Lua/parser
  and QML lint. Host fish/ShellCheck unavailable; CI checks those tools.
- Real Quickshell offscreen scratch-HOME harness loaded BluetoothPanel with mock
  adapter/device objects; tested discovery lifecycle, replacement, preservation
  of pre-existing discovery, and connection guards. The standalone Qt runner
  cannot load Quickshell's statically embedded Bluetooth plugin; this separate
  harness is run by Python when qs is available and skipped explicitly otherwise.
- Installed Quickshell 0.3.1 Bluetooth qmltypes inspected. Known metadata warning:
  Bluetooth.defaultAdapter has an unresolved BluetoothAdapter return type in
  qmllint; real runtime loaded. PanelWindow lint warnings are also emitted.
- Candidate shell deployed to existing guest; no adapter state visually inspected
  in expanded pull-down. Tracked screenshot: assets/screenshots/phone-bluetooth.png
  on review/pr-24-fix. Local captures/log: build/pr-review/pr24-*.png and
  build/pr-review/pr24-check.log. VM backup: ~/tessarchy-backups/pr24-before/shell.
- Guest has no BlueZ service/adapter; actual power, discovery, connection,
  permissions, hot unplug and battery accuracy remain hardware acceptance work.
- No new ISO release was produced, published or claimed boot-tested. PR CI's
  image build does not make these changes part of published Alpha 2.

Preserved #9 continuation details:
- Full unresolved merge work remains in build/integration; local pr9-check.log
  ended successfully. It has a safer owned-PID OSK restart, theme picker/palettes,
  launcher wrapper and icon tint changes that are NOT yet committed or pushed.
- Do not rerun /tmp/tessarchy-pr9-resolve.py or /tmp/tessarchy-pr9-safety.py blindly;
  they would overwrite subsequent edits. Guest currently runs #24, not #9.
- Verify new theme helper destinations before deployment, test dark/light themes
  and wrapper launch in VM, then document, commit, push, pass CI and merge #9.

## Final Bluetooth #24 result

- MERGED on main: e2e4f124d131ab8b35a258e30e52072d6d6b409b.
  Shareable link: https://github.com/thediamondsaint/tessarchy/commit/e2e4f124d131ab8b35a258e30e52072d6d6b409b
- Source CI 39067988279: Ubuntu and Arch jobs passed. Arch includes fish and
  ShellCheck plus the real Quickshell mock-adapter harness.
- ISO CI 39067988276 passed; tester-draft was intentionally skipped for this PR.
- build/live-iso merged origin/main without conflicts, preserving handoff history.
  Root ./scripts/check.sh passed again: 31 Python and 22 Qt checks; log is
  build/pr-review/pr24-root-check.log. This was the final merged-tree validation.
- Guest candidate remains active, native 400x800, pull-down closed after capture.
- #9's unfinished merge is preserved. The next agent should finish that work
  and then merge the newer main baseline (including #24) before pushing #9;
  retain the Bluetooth panel, PlainText labels and themed glass styling together.
- The user's request for this turn (#24, Git update, handoff, shareable commit)
  is complete after the final handoff push. Other PRs remain authorized future work.

## Effort-ordered PR pass

The owner requested scanning all remaining PRs, sorting by ease, and skipping
disruptive or difficult changes for now. The complete ranked assessment is
docs/pr-triage.md. Current intended small batch: #15 media, #17 audio, #18 power,
#14 screenshots, subject to review and passing checks. Other PRs remain open;
#16 overlaps the existing card previews. Preserve #9's uncommitted merge.
New worktree build/quick-prs is initially review/pr-15-fix, integrating current
main into the original contributor head without rewriting history.

## Easy-PR pass results, 2026-10-17

All 15 remaining open PRs were scanned for incremental scope, dependency chains,
conflicts with current UI, metadata compatibility and validation needs. Ranking
and per-PR defer reasons are in docs/pr-triage.md. This pass takes #15, #17 and
#14 only; #18 was initially considered easy but missing-service handling requires
more work because installed PowerProfiles has no availability flag. Other open
PRs remain unchanged; #16's old grid previews are superseded by current cards.

#15 media — MERGED
- Reviewed source: 00bad586201f68ce3604b160d6e2bfbd97b895e3.
- Main merge: 81d798872121bf21329da53f55726702cdf51619.
- CI: source 39077751343 (Ubuntu/Arch passed), ISO 39077751336 passed.
- Local: 31 Python and 26 Qt Quick checks. Actual MediaPanel with mutable mock
  player tested unsupported actions, control refusal, changes, seek and removal.
- Current glass pull-down, icon actions, PlainText metadata, guarded MPRIS calls;
  no top-bar crowding or obsolete status-page restoration.

#17 audio — MERGED
- Reviewed source: f8ff894408892a1765beaeb74d6a4dc99d0a3651.
- Main merge: 97ffc6208c90f47c82399139b8428b5284cb5fe9.
- CI: source 39077872284 (Ubuntu/Arch passed), ISO 39077872170 passed.
- Local: 32 Python and 30 Qt Quick checks. Actual controls tested with mock nodes
  and actual Quickshell/PipeWire wrapper started in an isolated no-service runtime.
- Advanced section loads only when expanded and backend enabled. Track candidate
  nodes before readiness filtering; display only ready output/audio playback
  nodes; guarded output selection, bounded per-app volume and mute. Existing basic
  volume controls remain. Capture/video streams excluded, metadata PlainText.

#14 screenshots — MERGED
- Reviewed source: c91b9eef6e9f3082eea81f89ff90373be3de711c.
- Main merge: 39d4379c4a1dda441e9b27c250543a6a6f57ec11.
- CI: source 39078004550 (Ubuntu/Arch passed), ISO 39078004547 passed.
- Local: 35 Python and 30 Qt Quick checks; parser/lint/staging passed.
- Unique mktemp private 0600 files fix same-second overwrite. Partial files are
  removed on capture failure; optional notification failure preserves captures.
- Print binding and glass camera icon; drawer closes before a delayed capture.
  Existing safe manifest and launcher refusal/modification checks preserved.
- Stub tests cover duplicate timestamps, existing file preservation, permissions,
  notification failure, capture errors, missing grim, argument refusal and staging.

Limits for this pass: no real-player MPRIS, real-device PipeWire, actual screenshot
capture or new VM visual/touch checks. The SSH socket expired and access was not
available; controls have isolated component/backend tests instead. Hardware and
end-to-end VM acceptance remain pending in docs/testing.md. No ISO release was
published and no new boot claim made. Host fish/ShellCheck were skipped locally,
then passed in the target CI jobs for the merged PRs.

One-off local integration scripts are /tmp/tessarchy-pr15.py, pr17.py, pr14.py
(with tessarchy- prefix). Do not rerun these over newer edits. Checks/logs are
build/pr-review/pr15-check.log, pr17-check.log and pr14-check.log.

## Final easy-PR batch state

- #15, #17 and #14 are merged. Other 12 open PRs were left unchanged/deferred.
- Combined main commit: 39d4379c4a1dda441e9b27c250543a6a6f57ec11.
  https://github.com/thediamondsaint/tessarchy/commit/39d4379c4a1dda441e9b27c250543a6a6f57ec11
- Root build/live-iso merged main without conflicts and preserved both histories.
- Final ./scripts/check.sh from the root passed 35 Python and 30 Qt Quick results.
  Log: build/pr-review/easy-batch-final-check.log. Known Quickshell Bluetooth
  metadata/PanelWindow lint warnings remain; no new runtime failure was hidden.
- No additional images/screenshots or release assets were created in this pass.
  Mock screenshots used for helper tests are not actual graphical captures.
- Ranking and handoff are committed on build/live-iso and should be pushed before
  handing control back. Read the top/current sections before historical entries.

## Phone login candidate checkpoint

- Active root branch: feat/phone-login, based on the synchronized easy-PR batch.
- New PinScreen: phone clock/date/logo, glass >=48px keys, four dots, delete icon,
  keyboard input, auto-submit after exactly four digits, compact 320x568 layout.
- New PinLoginController: one secret PAM challenge only; failure/extra/visible
  challenges and passwordless success cannot launch a session. Fixed launch is
  /usr/bin/start-tessarchy. Pending strings cleared after response/failure;
  no secure memory-zeroing claim. 30-second deadline and 3-second retry delay.
- New greeter entry point uses Quickshell Greetd; separate minimal Hyprland Lua
  loads no user config. Launcher exits that compositor after QS exits so greetd
  can start the real session. Failed cancellation requests a greeter restart.
- Opt-in tessarchy-greeter package selects a namespaced greetd config through a
  systemd drop-in. No PAM-stack override, service auto-enable or default PIN.
  Source/package check scripts updated; normal dev installer/ISO boot path intact.
- ./scripts/check.sh passed 42 Python and 37 Qt Quick results. Protocol integration
  tests run real Quickshell with a fake greetd UNIX socket (not actual PAM).
- Local package builds passed. Final artifacts: build/phone-login-packages-final/.
  Earlier build/phone-login-packages/ is superseded. Packages were not installed.
- VM SSH control socket vm/ssh-control restored with a four-hour control lifetime.
  No credentials copied into files. greetd is absent; dry-run dependency plan
  reports greetd and greetd-agreety. No package or account setting was changed.
- Preview source is isolated in ~/tessarchy-login-review/shell; running preview
  QS instance xg5vtr2nt (verify current PID/instance before acting). Existing real
  Tessera and Foot QA windows remain. Preview is fullscreen and explicitly tagged
  “Preview · sign-in disabled”; it does not authenticate or launch a session.
- Native VM 400x800 restored after 320x568 visual check. Touch-simulated keypad
  and synthetic keyboard entry worked, with masked dots and automatic clearing.
- Tracked captures: assets/screenshots/login-preview-phone.png and
  login-preview-small.png. Raw captures/logs/input helper: build/pr-review/phone-login-*
  and build/pr-review/login-keys.py; guest helper /tmp/tessarchy-login-keys.py.
- Activation and rollback plan: docs/phone-login.md. Real PAM/boot/session handoff
  checks remain pending, as do credential selection and dependency permission.
- No secure locking claim; this is a pre-session greeter, not an overlay lock.

## Activated login and logo pack checkpoint — latest

Owner approved installation/testing/restart and chose the account PIN. Do not
ask again or record the credential. Dependencies and local source packages are
installed only in the VM; no host configuration/package change occurred.

- greetd 0.10.3-2 and greetd-agreety installed; local session dependencies also
  installed grim/libnotify. Three source packages installed under /usr/bin and
  /usr/share/tessarchy. Greeter account is UID/GID 967, home /var/lib/tessarchy-greeter.
- Source package now provides a private tmpfiles directory and explicit HOME for
  greeter portability; Arch's package originally gives greeter the unwritable /.
- greetd.service enabled, getty@tty1 disabled, graphical.target was already set.
  No tty1 autologin override existed. Backup: /root/tessarchy-login-before/systemd.
  The stock PAM stack is unchanged. /etc/tessarchy/login-user is arch.
- The selected account password was changed via hidden stdin to chpasswd, not
  command arguments/files. SSH reconnected successfully after reboot. Never store
  or echo the PIN or old credentials. Root backup contains no copied shadow file.
- VM was rebooted once. QEMU uses -no-reboot and exited; relaunched after confirming
  the old process was gone. New QEMU PID 234086 (verify). Saved argv (no credentials):
  vm/phone-login-qemu-command.json. The old temporary source share had been cleaned
  up, so build/source-share.hOIYSt was recreated before relaunch; no disk race.
- SSH control socket vm/ssh-control restored, four-hour lifetime. The account's
  new credential is active; do not try the previous password or save credentials.
- Real PAM wrong-PIN rejection captured; no Tessera session started on failure.
  Real chosen-PIN success then started user Hyprland/Tessera. Session exit via the
  actual confirmation screen returned to greetd's phone screen. There were no
  user applications in the new test desktop when it was ended for these checks.
- VM testing found a follow-up backend error overwrote the rejected-PIN text.
  Controller now does not cancel an already-ended auth failure and preserves the
  rejection message against the follow-up error. Fixed state was exercised in VM.
- Actual captures in build/pr-review: phone-login-real-ready.png,
  phone-login-rejected-v2.png, phone-login-success.png. They are genuine greeter/
  PAM results, distinct from the earlier preview images. No PIN visible.
- User reported two messages at Hyprland load. Logs confirm direct Hyprland launch
  warning. Both source launch paths now use start-hyprland -- --config. Installed
  current greeter uses watchdog and its logs have no WARN/start-hyprland warning.
  Still verify user session through the updated launcher. Both configerrors were
  empty. Separate virtual-GPU diagnostics (gamma/page-flip/EGL fallback) exist in
  logs and are not falsely claimed eliminated or hidden.
- The private ~/.local/bin/start-tessarchy exactly matched the prior source SHA
  b9b038012f6cca431bc237a70a5e7228251c5b45c83f3b2cb24ca33abe58e52d before updating.
  Backed up at ~/tessarchy-backups/login-launcher/start-tessarchy, then updated.
- Latest checks: 43 Python and 37 Qt Quick passed, both Hyprland parsers/lint.
  Log build/pr-review/phone-login-v3-check.log. Current v4 only adds optional greeter
  output/mode environment knobs; run checks again if other code changes occur.
- Package builds v1/final/v2/v3 all passed; v4 final source build is running or
  finished under build/phone-login-packages-v4/. Use newest, not earlier archives.
- Current draft PR: https://github.com/thediamondsaint/tessarchy/pull/25.
  Initial commit b9803624d66794dd4cbd5c3fb2b0e2eb3feaf2c8 passed Ubuntu/Arch/ISO CI
  (39079577447 / 39079577407); final uncommitted fixes/exporter still need pushing.

Logo kit:
- ZIP: dist/tessarchy-logo-kit-20261017/Tessarchy-Official-Logo-Kit.zip
- SHA256: c768b5126c13b3ea58bf21615d713fa171194a336e424cc6f4baff07a45fb39e
- 59 entries, 5,544,035 bytes; ZIP CRC and every manifest digest validated.
- Original mint SVG is byte-identical to shell/artwork/tessarchy-mark.svg.
- Transparent mint/white/black PNG at 16–2048px (12 sizes), SVG variants, lossless
  WebP, navy JPG, multi-size ICO, vector PDF, MIT license, README and manifest.
- Animated/ contains 256/512 navy-matte 3D-style GIF spin, animated WebP, transparent
  flat-spin GIF and animated SVG. GIF/WebP have 72 frames, 50ms/frame, loop=0.
- Main GIF: dist/tessarchy-logo-kit-20261017/Tessarchy-Official-Logo-Kit/Animated/tessarchy-logo-3d-spin-512.gif
- Contact sheet build/pr-review/logo-spin-contact.png visually inspected. This
  extends the existing vector asset using code; no new AI logo or redesign.
- Exporter refuses existing output and uses installed Pillow/rsvg-convert. No
  dependencies were installed on host. Generated ZIP stays under ignored dist/.

## Final login/branding validation checkpoint

- Real PAM wrong-PIN rejection and chosen-PIN success verified; session exit via
  confirmation returns to the greeter. Final watchdog login transition also passed.
- Greeter starts via start-hyprland; user desktop evidence reports watchdog=true,
  config_errors="", warnings=[]. Virtual-GPU diagnostic messages are separate and
  remain documented; nothing was hidden with a suppress-errors setting.
- Final source checks passed 43 Python / 37 Qt Quick. All three v4 packages built;
  v4 greeter installed. Global and known-owned private launchers use watchdog.
- Greeter root config persists Virtual-1 400x800@60 via environment knobs. The
  actual screenshot is assets/screenshots/phone-login.png; rejection and success
  captures are phone-login-rejected.png / phone-login-home.png. These are real
  authentication evidence, not preview or ISO boot evidence.
- User session deliberately still selects its private development Tessera source;
  existing preferences preserved. Root-managed greeter runs installed package.
- VM currently logged in to Tessera, native 400x800, no app windows created by the
  final test. QEMU PID 234086 and SSH control socket remain active (verify).
- Finish commit/push and CI for final fixes and scripts/export-brand-assets.py;
  update PR #25 around actual finished scope, merge after checks pass, then sync
  build/live-iso without discarding handoff history. Logo ZIP is ready to deliver.

## Roadmap and public showcase checkpoint — 2026-10-17

- Login PR #25 merged after Ubuntu/Arch/ISO CI passed. Merge commit:
  ff53bd674b3aeb96a87105e98e2a585a86bd3df3. Local build/live-iso fast-forwarded
  to origin/main before the website update; no contributor history was discarded.
- Latest owner request: professional roadmap image and update Git/site with
  current information and many images, ready to share to a channel. No message
  has been sent to any channel; docs/community-update.md is prepared for copying.
- Roadmap: assets/roadmap/tessarchy-device-roadmap.png, 1024x1536, curated final
  publication artwork. Built-in image generation with official logo reference;
  correction pass fixed 00–06 sequence and concept device captions. Full prompt:
  docs/device-roadmap-image-prompt.txt. Milestone source: docs/device-roadmap.md.
- Final PNG SHA256: 5e2263de2c447b1cca7f5ce7b4a558d3cdbd15f17a20816f82869a30da92a720.
- Separate public asset release created, leaving Alpha 2 ISO unchanged:
  https://github.com/thediamondsaint/tessarchy/releases/tag/brand-kit-20261017
  Contains official logo ZIP, 512px spinning GIF and roadmap. GitHub digests
  verified against local files. It is explicitly not marked latest.
- Site retains the existing Quiet Edge presentation and collaborator history;
  adds real login/Bluetooth/post-login captures, current contributor integration
  status, planned hardware gates, full roadmap, branding downloads, sharing and
  Open Graph/Twitter metadata. Screenshot ZIP now includes eleven real captures.
- Both bundled and live release selection require an ISO asset, so a brand-only
  release cannot replace the tester download. Added meaningful regression test.
- Actual checks: 44 Python / 37 Qt Quick pass, git diff --check clean. Local fish
  and ShellCheck unavailable. New site build succeeds, browser checks pass using
  installed Chromium: desktop1440/mobile390 no overflow, static image decoding,
  keyboard tabs/focus, gallery/Escape and no uncaught script exceptions. Inspected
  desktop/mobile screenshots under build/site-refresh. No dependencies installed.
- Native mobile share sheet not tested. Hardware/real radio, media/audio and
  screenshot acceptance remain as recorded in docs/testing.md. No new ISO boot
  is claimed. Current user session uses its preserved private development copy.
- Immediate next step at this checkpoint: commit/push the showcase update, merge
  to main after CI, sync build/live-iso, confirm Pages deployment and live assets.
  Keep build/integration's deferred #9 merge untouched. Final checkpoint below
  will supersede these publication next actions when they are complete.

Publication follow-up:
- Showcase commit 78ea96d23b624895519a11ab5494a023833822c0 pushed to
  build/live-iso; PR #26 opened. Ubuntu/Arch checks and Pages run39082172625 passed.
- Brand release is marked prerelease and not latest so it does not become the
  project's stable software release; website also requires an ISO asset.
- Release-event run39081997323 failed before steps: existing environment rejects
  tag deployments. Removed obsolete release-event Pages trigger instead of
  weakening protections. Runtime public API keeps release information current;
  pushes/manual dispatch rebuild the fallback. Source update CI must finish before
  #26 merge. No tester ISO bytes were changed or newly boot-tested.

## Finished public showcase and Git sync

- PR #26 merged after all checks passed:
  https://github.com/thediamondsaint/tessarchy/pull/26
  Merge e1ff6a5891f04c5751630f7991bf3fb55665197d.
- Source update: 78ea96d23b624895519a11ab5494a023833822c0; deployment follow-up:
  d925ba44f8bd2f4902c849ec3a0090d51e20b542. Ubuntu/Arch runs39082298295 and
  39082301438 passed. Pages run39082298291 passed.
- Public website verified: https://thediamondsaint.github.io/tessarchy/
  HTTP200 current sections/social metadata; roadmap hash matched; screenshot ZIP
  CRC passed with eleven original PNGs; project.json selected the ISO release.
- Shareable roadmap:
  https://thediamondsaint.github.io/tessarchy/assets/tessarchy-device-roadmap.png
- Official logo ZIP and animated GIF are on the separate branding release:
  https://github.com/thediamondsaint/tessarchy/releases/tag/brand-kit-20261017
- docs/community-update.md contains a ready-to-copy channel post. No messages
  were sent to anyone. Native share sheet remains untested; public URL is shown
  directly and the desktop share path offers clipboard/fallback behavior.
- This documentation-only checkpoint follows the tested merged source. Publish
  it by fast-forwarding main and build/live-iso to the same commit; do not reset
  histories or touch collaborator/deferred worktrees. Website and source CI run
  again automatically. Verify their returned state before final user handoff.
- Next product work is optional, not an unfinished part of the requested showcase:
  validate newly merged media/audio/screenshot controls in the VM; then revisit
  deferred PRs under the owner's easy-first instruction. Physical reference-device
  selection/bring-up and PIN enrollment in a new ISO remain future work.
- Alpha 2 stays the same previously boot-tested x86_64 image; login/new integrations
  are source/development changes. No new ISO boot or physical hardware claim.

## Agent onboarding, direct documentation and image refresh

Owner requests:
- Root agent README with context, a shared plan/register and a long task list;
  publish to Git and return its URL.
- Direct technical documentation without repeated caveats; remember this style.
- Replace outdated tablet/desktop website images with current-feature captures.

Completed content:
- AGENT-README.md: onboarding, design, current implementation/evidence, repository
  map, runtime source precedence, commands, task claiming, contribution checklist
  and 56 task IDs T01–T56 across validation, 12 open PRs, UX, hardware and releases.
- Writing preference saved in AGENTS.md, AGENT-README.md and this file.
- README/CONTRIBUTING and active roadmap/GitHub-review docs rewritten directly;
  architecture/login/VM facts refreshed. Historical testing evidence preserved.
- Corrected a website/README overstatement from the prior showcase: Bluetooth
  pairing is external; native controls discover and connect already-paired devices.
- Agent guide linked from README, CONTRIBUTING, AGENTS and the website.

Current image provenance and VM state:
- Exact source9c1f4a3 archived into ~/tessarchy-capture-9c1f4a3 in the VM. Latest
  shell ran temporarily with isolated config and PATH. Existing source preserved.
- New tablet-home/tablet-controls captures: Auto Tablet, 800x1280 scale1.
- New desktop-home/desktop-controls captures: Auto Desktop, 1280x800 scale1.
- Source SHA, dimensions and hashes: assets/screenshots/capture-manifest.json.
- Four captures visually inspected; current quick controls show Bluetooth, audio,
  camera and media sections. No simulated radio/device/player states.
- Restored original private shell at400x800 and cursor visibility. Original shell
  preferences match the initial copied bytes. Current qs PID2318, config path
  /home/arch/.local/share/tessarchy/shell/shell.qml; verify runtime before use.
- Site ZIP now thirteen originals; mode preview can open matching controls views;
  image/script version query refreshes cached tablet/desktop and social images.

Actual checks so far: 44 Python /37 Qt Quick pass; fresh site build; all Markdown
file links resolve; 56 task IDs validated. Browser review uses installed Chromium
and screenshots under build/site-refresh. Finish current Git publication, source
CI and Pages verification; return the main-branch agent-guide URL. Keep the
integration worktree for #9 intact. No dependency install or VM reboot was used.

## Completed agent-guide publication

- Content commit: a251708fe68e718be2a9b57361e68b69839be777.
- PR: https://github.com/thediamondsaint/tessarchy/pull/27
- Merge: 3f512bc9ed76388ee82611f1654a914896700a4a.
- Ubuntu/Arch runs39083726072 and39083730802 passed; Pages39083726075 passed.
- Public four-image hash comparison and thirteen-PNG screenshot ZIP CRC/hash
  checks passed. Website has the agent link and per-mode quick-controls viewer.
- Agent guide: https://github.com/thediamondsaint/tessarchy/blob/main/AGENT-README.md
- Website: https://thediamondsaint.github.io/tessarchy/
- This completion record follows the tested merge. main and build/live-iso are
  synchronized when publishing it; automatic source/Pages jobs cover the final
  snapshot. Next agents should use fetched refs rather than historical SHAs.
- Original VM shell/preferences restored at400x800. Current capture source and
  evidence are retained for future screenshot refreshes. No host config changed.
