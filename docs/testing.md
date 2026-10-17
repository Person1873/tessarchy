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
