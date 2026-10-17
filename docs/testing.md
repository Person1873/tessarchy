# Validation and manual acceptance

## Actually performed, 2026-10-16

Environment: Omarchy/Arch, Hyprland 0.56.2-2, Quickshell 0.3.1-1,
QEMU 11.1.1, Foot 1.28.0. archiso and Firefox were not installed in this session.
The repository was new; no earlier Tessarchy prototype files were found in the
workspace. Existing projects and host session configuration were preserved.

`./scripts/check.sh` passed:

- Bash syntax for scripts, launchers and package recipes.
- Six integration tests: install/uninstall preservation, existing-path refusal,
  modified-launcher refusal, removal-marker/extra-file safety, nested-session
  refusal, and ISO staging against a minimal fixture with boot-asset and
  account-database preservation. This is not an archiso build test.
- Lua syntax and Hyprland's actual `--verify-config` parser: `config ok`.
- Qt qmllint against installed Quickshell metadata: exit 0. It warns that
  PanelWindow is not creatable; Quickshell chooses its backend at runtime, and
  the warning does not demonstrate working rendering. Shellcheck was absent
  and was explicitly skipped.

A sparse 32GiB qcow2 was created and inspected using qemu-img; initially only
about 200KiB was allocated. The launcher printed a TCG VM plan. A headless,
paused QEMU/TCG smoke test with the disk in snapshot mode initialized and stayed
alive for three seconds; then it was terminated. This tests the emulator engine
and disk attachment only, not firmware, boot, graphics, NAT, or the OS.

A Quickshell offscreen attempt failed because no PanelWindow backend exists
without a Wayland/X11 backend. The session also restricts local IPC sockets.
It is **not** a GUI pass. The installed host desktop was not altered or used
to run the prototype. Outbound download DNS is blocked here; /dev/kvm is not
exposed and privilege escalation is unavailable. Real ISO staging stops with
an explicit missing-archiso diagnostic. No Arch guest or Tessarchy ISO boot was
performed. Both local Arch packages were subsequently built successfully with
`./scripts/package.sh`; package metadata and file lists were inspected. They
have not been installed or runtime-tested. No built ISO is claimed.

## Manual checklist (detailed acceptance pending)

Record guest package versions, output mode/scale, input device, and logs. Treat
any failure below as a blocker for claiming the first session milestone works.

- [ ] Boot a stock Arch VM and install the documented dependencies explicitly.
- [ ] Install the dev copy as a normal user; confirm existing host/guest configs survive.
- [ ] Launch from a local TTY; verify no Hyprland configuration error banner.
- [ ] At 320×480 and 360×640 logical portrait sizes: all three dock buttons fit,
      labels remain usable, drawer scrolls, all controls are at least 48px, and
      close confirmation remains reachable. Test touch scrolling on hardware.
- [ ] At 800×1280 and 1280×800 tablet sizes: panels fit without excessive stretching,
      no unexpected tiling/split claims, dialogs and app minimum sizes are usable.
- [ ] Repeat at 1×, 1.5× and 2× scale, including output resize/rotation.
- [ ] Apps opens Firefox and Foot; rapid separate taps are not silently dropped.
- [ ] New ordinary windows maximize initially; multiple open apps can be switched
      through Windows, including windows on another workspace/output.
- [ ] Maximize and Restore affect exactly the chosen window; the dock stays visible,
      remains 72px reserved, and the label follows actual compositor state.
- [ ] Restore with several windows demonstrates tiling; document any policy gaps.
- [ ] Close asks confirmation, Cancel preserves the window, confirm closes only the
      named window. Unsaved apps may show their own dialog. Test spontaneous
      target exit while confirmation is open; no crash or wrong-window close.
- [ ] With text typed into Foot/Firefox, opening/closing Apps and Windows keeps
      keyboard focus in the app. Explicitly selecting another window changes focus.
- [ ] No hover is required. Test actual touchscreen input separately from the VM
      absolute pointer; trackpad gesture behavior is not a touchscreen test.
- [ ] Exclusive fullscreen behavior is recorded: dock may be hidden. App controls
      must provide a touch exit or keyboard recovery is required. No universal
      touch-only escape from exclusive fullscreen is implemented in milestone 1.
- [ ] Session → Cancel preserves session; Session → End returns to TTY; restarting
      works. Recovery shortcuts and alternative TTY work through QEMU Send Key.
- [ ] Uninstall preserves preferences/other configs; install again successfully.
- [ ] Build local packages and explicitly install/remove them in the guest.
- [ ] Stage with actual archiso, review profile, build, record output/hash and log.
- [ ] Boot Tessarchy ISO in BIOS and OVMF modes; test user creation, autologin,
      ownership, non-root rendering, apps, networking, audio and session exit.
- [ ] Confirm root rescue behavior, disabled SSH, no accidental sudo grant, and
      lack of persistence; review services/sockets before distributing an image.

Secure locking and on-screen typing are not implemented and cannot be marked
passed. First-milestone touch accessibility is limited to shell navigation with
maximized apps; application UI and exclusive fullscreen escape remain constraints.

## Basic guest conversion workflow, 2026-10-16

The user reports that the official Basic image boots. This is user-reported
Arch boot success, not an agent-observed Tessera GUI pass. Added a launcher for
that existing image, fresh read-only source sharing, guest-only setup, and a
reversible tty1 login hook. All nine workflow tests pass, including a QEMU stub
that checks disk selection/share contents and preserves the guest image, plus
login-hook roundtrip, idempotence and modified/symlinked profile refusal.
The real launcher command was inspected using `run-basic-vm.sh plan`.
Hyprland config parsing and QML static checks still pass (same known tooling
warning); shellcheck remains unavailable. The actual guest has not been changed
by the agent. Dependency installation, Tessera graphics, tty1 login startup and
VM graphics compatibility still require running the documented guest commands.

## First graphical smoke test, 2026-10-16

The user confirms Tessera runs in the Basic Arch QEMU guest and its dock is
visible and working. This is a user-reported graphical smoke test; the agent
has not observed the guest screen. Exact guest package versions and detailed
results for switching/maximize/close/focus/scaling were not captured. The full
manual checklist remains pending; actual touch hardware and ISO boots remain
untested. Before the initial Git commit, all nine workflow tests and available
static checks passed again, with the previously documented qmllint warning and
shellcheck skip. Generated VM images, downloaded data, packages and build output
are excluded from Git.

## Script hardening and validation record, 2026-10-17

Environment: Omarchy/Arch host, Hyprland 0.56.2, Quickshell 0.3.1, Qt 6.11.2
(`/usr/lib/qt6/bin/qmllint`), desktop-file-utils 0.28, python 3.14, qemu absent.
All work ran as the normal user; no host session config, `dist/`, `build/` or
`vm/` content was disturbed beyond this project's own ignored directories.

- The host had a stray `qmllint` (reports version "1.0") on PATH which fails
  silently with exit 255 on the shell QML. `scripts/check.sh` now prefers
  `/usr/lib/qt6/bin/qmllint` matched to the installed Qt before a PATH entry;
  after the fix `./scripts/check.sh` exits 0, still reporting the known
  PanelWindow warning.
- `desktop-file-validate` on `session/tessarchy.desktop` flags the spec-valid
  `DesktopNames` Wayland-session key as an extension-key error ("0.28"). The
  check tolerates only that specific quirk and fails on any other finding.
- Integration tests grew from nine to seventeen with stub-based checks:
  `vm.sh plan` command printing, missing-disk, usage and `VM_SSH_PORT`
  refusals; `fetch-arch-iso.sh` seeded-manifest stubs proving an existing
  download is never overwritten and a failed download leaves no partial ISO or
  download directory; `build-iso.sh` explicit archiso refusal;
  `export-vm-source.sh` snapshot idempotence; `run-basic-vm.sh` missing-disk
  refusal. All 17 tests pass (grep count 17 `. ok`).
- Development install/uninstall now writes a `.tessarchy-dev-files` manifest;
  tests confirm installed files are removed, untracked extras are preserved,
  v1 markers still uninstall through the legacy fixed set, and the manifest
  itself is removed. `cmp` launcher-modification refusal was unchanged and
  still passes.
- `./scripts/package.sh` was run unprivately with the current source: both
  packages built (`--nodeps`, fakeroot). File lists and `.PKGINFO` were
  inspected by bsdtar; nothing was installed.
- The QML app launcher now derives entries from Quickshell `DesktopEntries`
  (validated against installed `quickshell-core.qmltypes`: `applications`,
  `noDisplay`, `command`, `execute`). Only qmllint validated it; no GUI run.

Not performed: archiso staging/build, ISO boot, VM launch, shellcheck (still
absent locally; covered if CI is enabled), touchscreen tests, guest installs.
