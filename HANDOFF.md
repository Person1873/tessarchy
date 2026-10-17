# Tessarchy handoff for Hermes or another model

Last checkpoint: 2026-10-17, during pull-request integration. This file is the
persistent continuation record requested by Charles. Keep it in the Tessarchy
folder and update it after each meaningful merge, validation, or blocker.
Never include passwords, tokens, SSH private keys, or other credentials.

## Current user request

Review the GitHub pull requests, resolve conflicts and defects, test the changes,
and merge those that are ready. The earlier instruction to leave collaborators’
PRs unchanged was superseded by this explicit request to get them merged.
Do not discard contributor changes simply because they conflict with the newer UI.
The user also wants a large, current handoff file for another model when credits
run out. The file must stay in the Tessarchy directory.

## Communication and working rules

- Use standard technical English in code and responses. Keep comments to one line.
- Be concise and direct. Continue authorized work without routine confirmation.
- Give meaningful progress updates at least once per minute during active work.
- Follow the root AGENTS.md. Do not modify the host’s Hyprland/Omarchy settings.
- Do not install dependencies automatically on the host or development guest.
- Run ./scripts/check.sh; use scratch HOME for installer/uninstaller tests.
- Keep touch targets at least 48 logical pixels, preserve app keyboard focus in
  navigation, and confirm window close and session exit.
- Do not accept a contributor branch’s claimed owner exception to AGENTS.md
  without reconciling it with the user-provided instructions. PRs #11/#20 contain
  a proposed exception for keyboard key widths; the current instruction still
  requires targets >=48 in both dimensions.
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

1. Repository root: branch build/live-iso. It contains the tested Alpha 2 source
   and subsequent release documentation. Before adding this handoff its tip was
   8c67414921621ce87f7ae1cf908a70b9266b4d27. This is the website/development branch.
2. build/publish: branch feat/phone-shell. It was synchronized to the tested
   Alpha 2 tree with merge commit e71ae0e and pushed. That synchronization was
   used to complete PR #1.
3. build/integration: active PR-review worktree. Currently branch review/pr-4-fix,
   with an in-progress merge of review/pr-3-fix into the original PR #4 head.
   The remaining merge conflict is scripts/check.sh: retain BOTH the fish syntax
   check and desktop-file validation. No conflict should be silently discarded.
4. origin/main now includes merged PRs #1 and #2. Fetch before relying on its tip.
5. Remote review/pr-N refs (under refs/remotes/review/) hold the original fetched
   PR heads. Fixed local branches review/pr-2-fix and review/pr-3-fix preserve
   contributor history and merge the newer baseline into those heads.

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

### PR #3 — fixed and pushed, NOT YET MERGED

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
CI ISO build for the pushed PR #3 head must be checked before merge.

## Current immediate next actions

1. In build/integration, finish PR #4 merge conflict in scripts/check.sh by
   keeping the fish syntax check and the desktop-file validation block.
2. Inspect the guest screen: it was resized to 1280x800 for PR #3, and the last
   action requested session-exit confirmation. Cancel it; DO NOT confirm exit.
   Restore native 400x800 after desktop validation using hyprctl eval (below).
3. Check PR #3 CI status; if successful, merge it using its full expected head.
4. Review/test/commit PR #4 integration, push to contributor fork feat/bundle-fish,
   wait for checks, then merge. Fish is not installed on the host; do not install
   it automatically. Its syntax check may skip locally. CI/live boot validation
   must be recorded honestly. The PR adds fish to the ISO, changes tess’s login
   shell, stages skel config, and leaves root rescue/development shells alone.
5. Continue #5 rootfs hardening, #6 portable checks, then remaining contributions
   in dependency order. Update this file after each meaningful step.

## Pending PR inventory and dependency cautions

All contributor PRs were retargeted from feat/phone-shell to main after #1
merged, as their descriptions requested. Their heads were preserved except
for the reviewed/fixed #2 and #3 updates described above.

- #1: Add Quiet Edge mobile shell, card switching and pull-down controls. Merged. Original state: draft.
- #2: Harden install tooling and fill the app drawer from desktop entries. Merged. Original state: open.
- #3: Add a desktop workspace strip, focused-window title and desktop keybindings. Fixed/pushed; CI/merge pending. Original state: open.
- #4: Bundle fish as the live user's login shell. Review pending. Original state: open.
- #5: Harden the live rootfs identity and runtime defaults. Review pending. Original state: open.
- #6: Make the source checks portable and add a checks workflow. Review pending. Original state: open.
- #7: Integrate squeekboard as an optional on-screen keyboard. Review pending. Original state: draft.
- #8: Keep Phone/Tablet apps maximized and fit oversized dialogs. Review pending. Original state: draft.
- #9: Carry the system theme through shell, keyboard and apps (Omarchy themes). Review pending. Original state: draft.
- #10: Touch file dialogs on Phone/Tablet (portal backend + GTK3 module). Review pending. Original state: draft.
- #11: On-screen keyboard rows fit 48 logical px. Review pending. Original state: draft.
- #12: Tablet split: two apps side by side with touch controls. Review pending. Original state: draft.
- #13: Add notification pop-ups and an alert center. Review pending. Original state: open.
- #14: Add full-screen screenshots from Quick controls and the Print key. Review pending. Original state: open.
- #15: Add MPRIS media controls to the status bar and Quick controls. Review pending. Original state: open.
- #16: Show live window previews in the app switcher. Review pending. Original state: open.
- #17: Add a PipeWire audio panel to quick controls. Review pending. Original state: open.
- #18: Add a battery and power-mode panel to quick controls. Review pending. Original state: open.
- #19: Add display controls: brightness helper, keys and a night-light toggle. Review pending. Original state: open.
- #20: Keep the keyboard hidden while a shell page is open. Review pending. Original state: draft.
- #21: Blank the idle panel after five minutes with hypridle. Review pending. Original state: open.
- #22: Rotate the focused display from Settings in 90° steps. Review pending. Original state: open.
- #23: Connect Wi-Fi from Quick controls through NetworkManager. Review pending. Original state: open.
- #24: Add Bluetooth quick controls to the shell. Review pending. Original state: open.

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
- PRs #11/#20 modify AGENTS.md to claim a keyboard-width exemption. The current
  user-provided AGENTS.md still requires >=48 logical pixels; reconcile this
  explicitly rather than silently lowering the instruction.
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
