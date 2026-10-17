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

## Phone shell and SSH guest validation, 2026-10-16

Actually performed by the agent on the existing Basic Arch qcow2 through SSH
on host loopback port 2222. The VM runs with KVM, 2GiB RAM, Hyprland 0.56.2-4
and Quickshell 0.3.2-1. Guest source and installed defaults were archived under
`~/tessarchy-backups/` before updating; the host desktop configuration was not
modified. No dependencies were installed.

- `./scripts/check.sh` passed on host and guest: nine workflow tests (including
  scratch-HOME install/uninstall), Lua parsing, Hyprland `--verify-config` and
  QML checks. Shellcheck is unavailable. qmllint retains its PanelWindow backend
  warning; an additional guest type-inference warning was resolved by using the
  screen model directly. Installed host/guest QML metadata was inspected.
- Guest `hyprctl reload` succeeds and `hyprctl configerrors` is empty.
- The agent inspected guest screenshots at 664×480 landscape and 432×768 logical
  portrait (1920×1080 output, transform 1, scale 2.5). Status and bottom navigation
  reserve 48 and 72 logical pixels respectively. The final app tiles and dialogs
  were inspected in portrait.
- Injected pointer clicks through a temporary guest-only uinput device: Home
  opens the launcher, Terminal launches Foot, and Recents shows the window.
  Foot is maximized at position (0,48), size 432×648, between both bars. Opening
  Recents keeps Foot as the active keyboard window. Close opens confirmation;
  Cancel preserves Foot. The top power control opens session confirmation.
- The gradient background, date/time, navigation icon alignment, launcher, recent
  apps, and confirmation screens were visually inspected. Evidence is local in
  ignored `build/phone-*.png`; no VM image or credentials are tracked.
- The guest lacks UPower and desktop portals. Battery status shows an unavailable
  indicator rather than an invented charge value. Live tray registration, tray
  menus, battery changes, browser launch, actual touch, and session exit have not
  been tested in this pass. The VM remains running.

ISO/publishing result: pushing the existing `build/live-iso` branch was rejected
by GitHub because the current OAuth login lacks the `workflow` scope. The workflow
dispatch consequently returned 404. `archiso` is absent locally, local Docker
access requires administrator authentication, and no build has run. No Tessarchy
ISO artifact or ISO boot success is claimed. Grant the GitHub workflow scope,
push the branch, and dispatch `.github/workflows/build-iso.yml` to continue.

Remaining manual checks: destructive close/session exit, multiple windows,
restore/resize, 320×480 and tablet layouts, hardware touch and battery, tray menus,
ISO build and BIOS/UEFI ISO boots. Back dismisses shell panels; it does not inject
a browser/application Back key. Home opens the app launcher above running apps.

## QEMU orientation correction, 2026-10-16

The user reported that the rotated phone display appeared sideways in QEMU.
The earlier screenshot validated the compositor rendering, not the viewer's
orientation. Over SSH, backed up the guest preference and set Virtual-1 to
1280×960@60, scale 2, transform 0. Reload succeeded; `hyprctl configerrors` is
empty, and monitor state confirms transform 0 and 640×480 logical dimensions.
The updated compositor screenshot is `build/phone-upright.png`. User confirmation
of the viewer presentation is still pending. Host desktop configuration is unchanged.

## Native phone view, artwork, and status controls, 2026-10-16

Actually performed:

- Backed up guest source, installed shell, and Tessarchy preferences under
  `~/tessarchy-backups/` before deployment. No dependencies were installed.
- Selected a native 400×800@60 mode at scale 1, transform 0, over guest SSH.
  `hyprctl reload` succeeded and `configerrors` is empty; actual monitor state
  confirms 400×800 with 48px status and 72px navigation reservations.
- Made only the host's `QEMU (Tessarchy)` client float, then resized it to
  350×700. No host compositor configuration was edited. Inspected the viewer
  at its intermediate 390×700 size and final 350×700 size with the menu hidden:
  the full upright phone content fits without clipping or letterboxing.
- Generated and deployed an original wallpaper and editable SVG Tessarchy logo.
  Inspected guest screenshots showing both, translucent status/navigation bars,
  wireless/cellular unavailable indicators, volume and battery symbols.
- Clicked Home/Back with guest uinput and inspected the final launcher and
  wallpaper. Clicked the speaker and inspected Quick Controls: Wi-Fi
  unavailable, no modem, no audio output; sound buttons are disabled. The guest
  has no PipeWire service. Optional audio code loads only when its socket exists.
- Host checks pass: nine workflow tests including scratch-HOME installation and
  complete removal of the new artwork/components, Hyprland config verification,
  Lua and QML checks. qmllint retains the known PanelWindow warning; shellcheck
  remains unavailable. The final guest run of the same checks also passes.

During restart, Quickshell 0.3.2 aborted (guest PID 1131). `coredumpctl info`
shows SIGABRT in Qt's `QWindow::unsetCursor`/QQuickItem destruction path. Guest
memory remained available and no OOM kill was shown. This supports a Qt/window
teardown problem during restart; the exact upstream cause is unresolved.
Quickshell's crash handler restarted the shell and opened a crash dialog. The
old handler/dialog were stopped and the final configuration started cleanly.
PipeWire separately reported missing context configuration before the optional
backend guard was added; the core does not establish it as the crash cause.
No core dump or crash memory was copied into the repository.

Evidence: ignored `build/phone-branded.png`, `build/phone-controls.png`, and
`build/vm-phone-window-final.png`. Live Wi-Fi/cellular backends, real audio adjustment,
battery changes, hardware touch, and ISO builds/boots remain untested.

## Adaptive layouts, Settings, and logo animation, 2026-10-16

Actually performed:

- Archived guest source, installed defaults and preferences under
  `~/tessarchy-backups/` before updating. Host compositor configuration was not
  changed, and no dependencies were installed.
- `./scripts/check.sh` passes on host and guest: ten workflow tests and fifteen
  Qt Quick Test results (including fixture setup/cleanup). Tests cover auto-mode
  thresholds, portrait/landscape geometry, narrow manual override, Lua app policy
  with scaling/rotation and saved overrides, preservation of floating/fullscreen
  windows, finite logo playback, reduced-motion cancellation, and scratch-HOME
  install/uninstall preserving shell preferences and removing new assets.
  Hyprland verification returns `config ok`; QML checks retain only the known
  PanelWindow backend warning. Shellcheck remains unavailable.
- Resized the running guest to 400×800 Phone, 800×1280 Tablet, 1280×800 Desktop,
  and 320×480 Phone. Inspected Settings, header mode labels, adaptive navigation,
  launcher columns, scrollable controls, and a Desktop override at phone size.
  The final launcher uses row-based height rather than a mostly empty drawer.
- Used guest uinput to select Desktop/Automatic and Iris appearance. The actual
  `shell.ini` changed and the mode/accent loaded again after restarting Tessera.
  Inspected the longer Settings page after scrolling, including appearance,
  branded sliders, clock, labels, and motion controls.
- Guest `hyprctl reload` succeeds and `configerrors` is empty with the new Lua
  window-open policy. A temporary Foot test at 400×800 opens maximized at
  (0,48), size 400×680, fullscreen flag 1. Two temporary Foot windows opened
  at 1280×800 start tiled at (0,48) and (640,48), each 640×672, fullscreen
  flag 0. The test apps run `sleep` and exit naturally, with no user work in them.
- Rendered the actual BrandMark QML component offscreen into animation frames;
  inspected intermediate and final frames and produced the local preview
  `build/tessarchy-logo-animation.gif`. This is the component's animation, not
  a generated mockup. It assembles six original faces with rotation, runs once
  for 1.6 seconds, and settles. Qt tests verify no idle loop and reduced motion.

## Bundled fish live shell, 2026-10-17

Actually performed:

- Added `fish` to `iso/packages.x86_64`, changed the sysusers shell for `tess`
  to `/usr/bin/fish`, and gave the skel tree a fish profile: greeting off, two
  abbreviations, and the same gated tty1 one-shot Tessera start as
  `.bash_profile` (interactive only, tty1 only, no DISPLAY/WAYLAND_DISPLAY).
- `scripts/stage-iso.sh` now copies the whole skel tree to `/home/tess` and
  records `file_permissions` for the fish config; tmpfiles keeps the `.config`
  directories owned by `tess`.
- `fish -n` accepts the profile on the development host; `scripts/check.sh`
  now runs that syntax check whenever fish is installed.
- The ISO staging workflow test asserts fish in the package list, the fish
  login shell, the staged profile path, and the profiledef permission entry;
  all ten workflow tests pass on the development host.
- Not performed: building and booting the live image, verifying autologin
  lands in fish, or ending a session and returning to the fish prompt. Those
  remain part of the pending ISO boot checklist.

Screenshots are ignored under `build/`, including adaptive/tablet/desktop and
Settings captures. Hardware touch, real Wi-Fi/modem/audio/battery integration,
multiple physical outputs, exhaustive fractional scaling, and ISO builds/boots
remain pending. Auto detection classifies logical display size; it does not
identify physical device type or available input hardware. No secure lock claim.

## First published tester ISO, 2026-10-17 UTC

Actually performed:

- Fixed CI-only ShellCheck findings and archiso's package manifest collection
  path. The hosted CI ShellCheck step now passes; unavailable GUI/Lua tools in
  the Ubuntu pre-build check are explicitly skipped, not counted as passing.
- Actions run 38997819650 built the ISO in a disposable Arch container using
  archiso 91-1 from source commit `90c5eee58f8be68ae9b9a670c3479f0ff453449b`.
  Included versions: Hyprland 0.56.2-4, Quickshell 0.3.2-1, Linux
  7.2.10.arch1-1 and Mesa 1:26.2.4-1. No host dependencies were installed.
- The ISO is 1,070,628,864 bytes. SHA-256:
  `7bdacc213975c3c1b863100eff4686973d1a315389f6360ee4c7d3af68842608`.
  Verification passed in CI and matches GitHub's uploaded asset digest.
- Two diskless QEMU/KVM VMs (2 GiB, 2 vCPUs, virtio-vga, no NIC) booted the
  exact image through BIOS and non-Secure-Boot UEFI. The agent visually
  inspected both final screenshots at 90 seconds: each shows the Tessera GUI,
  wallpaper, clock, logo, status bar, mode badge and navigation after autologin.
  The first 120-second TCG attempts only reached Linux userspace, so they were
  not treated as graphical boot passes. Full capture evidence is attached.
- Published [v0.1.0-alpha.1](https://github.com/thediamondsaint/tessarchy/releases/tag/v0.1.0-alpha.1)
  as a prerelease with ISO, SHA256SUMS, package/build provenance and boot notes.
  The ISO is a release asset, never a Git-tracked binary.

Still pending for this exact ISO: app launch/actions, networking, audio, actual
touch hardware, multiple monitors, session exit, physical-device compatibility
and persistence acceptance. The installed development VM's broader tests above
do not establish these as passing in the ISO. No secure locking or Secure Boot
support claim. Testers should begin in a disposable VM with a physical keyboard.

## Quiet Edge and card switcher — 2026-10-17

Implemented in the development source and installed Arch VM; **not included in
published Alpha 1**. No replacement tester ISO was published during this UI/website change.
PR CI subsequently built an ISO successfully in run `39056992759`; that new
artifact has not been boot-tested and is not presented as the published tester release.

Actual validation:

- Reopened the existing QEMU/KVM guest with 2 GiB RAM and 2 vCPUs; retained native
  400×800 portrait output. Made its host window float using runtime dispatches;
  no host Hyprland/Omarchy configuration files were changed.
- Verified installed Quickshell QML type metadata for screencopy, desktop entries,
  IPC and layer keyboard focus, and Hyprland Lua metadata for layer rules/binds.
  Guest reload/configerrors was clean with the Tessera-only frosted layer rule.
- Visually inspected status bar, floating navigation, launcher, settings and
  card switcher. Switcher headings/instructions are absent; return/close actions
  are glass icon controls with accessible names and >=48px targets. App names
  and window titles remain visible. Close still opens an explicit confirmation;
  Cancel returned to the switcher without closing a window.
- Injected a real relative pointer drag through the guest's uinput interface and
  observed selection move between two real Foot cards. Window previews rendered
  through shared-memory screencopy; unavailable previews have an explicit fallback.
- Tested Alt+Tab using guest key input. Verified a change from the Project notes
  window (PID 503) to the development terminal (PID 502), with the selected app
  maximized at 400×676 below/above the reserved bars after releasing Alt. Fixed
  selection drift during dock expansion and deferred activation until the layer
  keyboard grab is released. Left/right and Enter were exercised in the switcher.
- Captured real development-VM screenshots at Phone 400×800, Tablet 800×1280,
  Desktop 1280×800, then restored the guest to 400×800. Source originals and
  capture limitations are in `assets/screenshots/README.md`.
- `./scripts/check.sh` passed on the host and guest: workflow safety tests,
  19 Qt Quick test results including lifecycle setup/cleanup, Lua syntax,
  `Hyprland --verify-config`, and qmllint. Known PanelWindow type-metadata
  warnings remain; ShellCheck was unavailable locally and in the guest.
- Website preview returned HTTP 200. Chromium/ChromeDriver rendered the site at
  1440×1000 and 390×844, with no horizontal overflow or broken sourced images.
  Layout tabs and screenshot dialog open/close worked; JavaScript syntax passed.
  The website builder also checks refusal to overwrite an existing destination
  and exact original screenshot bytes in the downloadable ZIP.

Still planned/manual: physical touch, multi-touch swipe tuning, additional app
classes and keymaps, multi-monitor keyboard routing, GPU-backed preview behavior,
performance on real mobile hardware, and a newly built/booted Quiet Edge ISO.
The VM lacks UPower and desktop portal services and falls back from DMA-BUF to
SHM preview buffers; these are not claims of working battery/network/audio devices.

## Pull-down quick controls and mobile clock — 2026-10-17

Actual validation in the installed development guest:

- Restyled the status clock with compact semibold digits, no leading zero or
  visible AM/PM suffix. Verified the saved 12-hour preference remains intact and
  the expanded clock/accessibility text still identifies AM/PM.
- Injected relative pointer drags from the status strip. A downward drag opened
  the glass sheet to 400×549; an upward drag collapsed it to 400×48, verified
  against compositor layer geometry. Tapping the clock also opened the sheet.
  The exclusive zone stays at 48px and keyboard focus is not requested.
- Confirmed the installed helper reports no Wi-Fi/Bluetooth/WWAN radios in this
  QEMU guest. Airplane mode and each radio tile correctly show Unavailable and
  remain disabled. No hardware state was simulated in the screenshot.
- Six radio tests cover absent devices, soft/hard blocks, independent radios,
  bulk airplane actions, permission failures, input validation and re-reading
  partially changed hardware after a failed bulk command. Commands are mocked;
  no host radio was changed. See docs/radio-controls.md for exact semantics.
- Host and guest `./scripts/check.sh` passed: 17 Python tests and 19 Qt Quick
  results, Lua/config validation and qmllint. Only the known PanelWindow metadata
  warnings remain. ShellCheck was unavailable locally/in the guest.
- Updated website preview rendered at 1440×1000 and 390×844, with working layout
  tabs and screenshot dialog, no horizontal overflow or broken sourced images.
  Added the real quick-controls image to the site's downloadable screenshot pack.

Still unverified: physical touch input, real transmitter changes, radio permission
policy on target hardware, modem-specific behavior and devices without rfkill.
These controls do not select networks, pair Bluetooth devices or provision mobile
service. Airplane off unblocks detected radios; previous per-radio selections are
not restored. No dependencies, services or host desktop configuration were installed
or changed. This UI update is not included in the published Alpha 1 tester ISO.

## Pull-down layout selector — 2026-10-17

Actual validation:

- `./scripts/check.sh` passed with 17 Python tests and 19 Qt Quick results;
  known PanelWindow metadata warnings remain and ShellCheck is unavailable.
- Installed the updated QML in the existing 400×800 development guest. Verified
  that the home-screen mode button is absent and the glass pull-down shows
  Auto, Phone, Tablet, and Desktop controls with targets at least 48px.
- Clicked Desktop in the pull-down, observed the active label and desktop dock
  update, and verified `layoutMode=desktop` persisted in the guest preferences.
  Clicked Auto, verified `layoutMode=auto` and the Phone layout returned.
- Collapsed the sheet using its handle and captured updated home and controls
  screenshots directly from the guest. No host desktop configuration changed.

Still planned/manual: physical touch and the selector on larger displays.
The published Alpha 1 ISO does not contain this change.

## Alpha 2 release rebuild — 2026-10-17

Actual validation:

- Reviewed open GitHub issues, pull-request status and Actions history. Recorded
  the inventory in `docs/github-review.md`; pending collaborator PRs are unchanged.
- Host `./scripts/check.sh` passed: 17 Python tests, 19 Qt Quick results, Lua
  syntax, Hyprland configuration verification and qmllint. Known PanelWindow
  metadata warnings remain; ShellCheck is unavailable locally.
- Actions run 39063437439 built the ISO from
  `aa8b59a73a8d5d6b1d3fab6c17272e68e0bfac58`, verified its checksum,
  and captured diskless BIOS and non-Secure-Boot UEFI QEMU/KVM boots.
- Inspected both final 1280×800 screenshots: Tessera's graphical home screen,
  current wallpaper/logo, glass status bar and floating dock are visible.
  Each guest used 2 GiB RAM, 2 vCPUs and virtio graphics, with no disk or NIC.
- Downloaded the published Alpha 2 ISO and verified its complete local SHA-256
  against `SHA256SUMS` and the GitHub release asset digest.
- Corrected the GitHub Pages environment policy to permit `v*` release tags
  alongside the existing `main` and `build/live-iso` branches. The release-event
  deployment passed on retry; no collaborator access or branch history changed.
- Built the website with public Alpha 2 metadata and verified its download
  selection and all seven screenshot originals in the bundled ZIP.
- Package manifest identifies Hyprland 0.56.2-4, Quickshell 0.3.2-1, Python
  3.14.8-1 and util-linux 2.42.4-1. Alpha 2 checksum matches the release digest.

Earlier development-VM interaction tests remain separate from these ISO boot
checks. Physical touch, network/radio/audio behavior, Secure Boot, phone
hardware and application acceptance are still unverified in this exact image.


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

## PR 2 integration review — 2026-10-17

Actual validation: resolved the app-drawer changes onto the Alpha 2 shell;
checked installed DesktopEntry/iconPath QML metadata; `./scripts/check.sh`
passed 26 Python tests and 19 Qt Quick results, Lua/Hyprland validation and
qmllint (known PanelWindow metadata warnings only; ShellCheck unavailable).
Scratch-HOME tests cover manifest install/uninstall, preserving unknown files,
legacy installs, traversal and symlink-parent rejection before any removal.
The development VM rendered the installed applications with their real icons
and truncated long names within the glass launcher.

Still planned/manual: additional desktop-entry command formats and theme changes.
No host desktop configuration or dependencies changed.


## Desktop mode workspace strip and keybindings, 2026-10-17

Implemented, static validation only; GUI and guest acceptance pending.

- `LayoutPolicy.js` gains `showWorkspaces(mode, width)` and
  `workspaceSlots(ids)`; `tests/qml/tst_layout.qml` covers placement at
  desktop/tablet/phone widths and slot extension beyond five workspaces.
- The status bar renders numbered workspace buttons from
  `Hyprland.workspaces`, highlights the focused/active workspace, and falls
  back to a numeric-only `hl.dsp.focus` dispatch for not-yet-created
  workspaces. Existing workspaces use `HyprlandWorkspace.activate()`.
- Desktop shows the focused window title beside the tray (display-only text).
- `session/hyprland.lua` adds fixed desktop bindings: Super+1-5,
  Super+Shift+1-5, Super+Q, Super+Tab, directional focus and window move,
  Super+drag/resize, and XF86Audio volume keys.
- Performed on the development host (Ubuntu ARM, no Wayland session):
  `luac -p` accepts the Lua config; `qmllint` (Qt 6.10) exits 0 for edited QML
  with only unresolved-module warnings; the Qt Quick Test suite was run
  directly against the multiarch Qt install and reports 17 passed, including
  the new `test_workspace_slots` and `test_workspace_strip_placements`.
  `scripts/check.sh` passes ten workflow tests with the documented skips
  (Hyprland and Quickshell absent).
- Not performed here: `Hyprland --verify-config`, Quickshell rendering,
  workspace strip taps, keybinding behavior, multi-output focus, or reduced
  width clipping. These require the Arch guest and remain on the manual list.

## PR 3 integration review — 2026-10-17

Actual validation: `./scripts/check.sh` passed 26 Python tests and 21 Qt Quick
results, Lua/Hyprland validation and QML lint. Inspected installed Hyprland
monitor/workspace/toplevel metadata. The guest rendered the desktop status
strip and focused title at 1280×800, and the close shortcut's IPC action opened
the confirmation page without closing Foot. The 400×800 status strip remains
uncrowded. Active-window lookup falls back to the activated Wayland handle
after shell restart. Workspace count is bounded and narrow overrides hide it.
Close and exit bindings route through the shell confirmations.

Still planned/manual: real keyboard layouts, physical touch and many workspaces.
This changes development source, not the already published Alpha 2 image.

## PR 4 integration review — 2026-10-17

Actual validation: reviewed tty1-only fish startup, live-user shell selection,
skel staging and ownership; `./scripts/check.sh` passed 26 Python tests and
21 Qt Quick results, Lua/Hyprland validation and QML lint. Staging tests confirm
fish package, sysusers shell, home profile and profile permission entries.
The host has no fish executable, so fish syntax validation skipped locally.
No dependencies were installed. The full live-image fish autologin/exit cycle
remains a planned boot check; Alpha 2 is unchanged.
