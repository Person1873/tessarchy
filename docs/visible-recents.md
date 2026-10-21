# Visible Recents entry in Phone and Tablet — issue #66

Owner decision (verbatim): "ok, I think just put the button back on the bar for both"

Restore a visible Recents button in both Phone and Tablet dock bars, including
when gesture navigation is selected. Keep the swipe-and-hold gesture as an
alternative. Preserve the existing switcher and Desktop taskbar behavior.

Splitting remains Tablet-only: restoring Phone Recents does not enable Phone
split controls. Do not treat a working hidden gesture as solving discoverability.

## Acceptance and coordination

Verify buttons and gestures modes in both touch layouts, a single-row narrow
320-pixel dock with horizontal overflow scrolling, touch activation of Recents,
and coexistence with the hiding dock from #64. Targets stay at least 48 pixels.
Desktop must remain unchanged. Run regression tests and inspect VM screenshots.

The change overlaps shell.qml with #63/#64/#67/#68; retain their functionality
when integrating. Do not replace installed source without comparing live edits,
and preserve the restored Quickshell.Networking Wi-Fi binding.

## Implementation and QEMU acceptance

Branch `fix/visible-recents` keeps the Recents NavButton visible in gesture and
button navigation, counts its slot in `dockLayout()`, and leaves Back/Home hidden
only in gesture mode. Both layouts share the same button; the Tablet-only
`SplitDivider.allowed` guard remains unchanged. No Desktop taskbar change.
Regression assertions cover touch dock counts and the actual button visibility;
the integrated one-row layout continues to scroll horizontally with 48px slots.

`./scripts/check.sh` on this branch: 214 Python tests, 76 Qt tests, zero
failures; fish and shellcheck unavailable. Integration with #62/#63/#64/#67/
#68/#74: public `verify/visible-recents` branch (based on
`sync/upstream-20261021` at `e7dc6b7`), 227 Python tests and 88 Qt tests,
zero failures. Python's one expected skip is environment-specific. Focused
workflow navigation test passed. Integration resolved two cherry-pick conflicts
in the policy and workflow test, retaining gesture dock shrink-to-fit and the
single #64 edge handler.

QEMU VM: virtual uinput touch, 1280x800 physical, scale 1 except for the
320x200 logical narrow pass at scale 4. On actual shell and real Foot clients:

- Phone Gestures: three dock buttons without OSK initially (Phone, Messages,
  **Recents**), four with OSK; touched Recents to open switcher, side Back
  gesture dismissed it, and a separate bottom swipe-and-hold reopened it.
  [Phone dock](evidence/visible-recents/phone-gesture.jpg),
  [gesture-open switcher](evidence/visible-recents/phone-hold-open.jpg).
- Phone Buttons: six buttons including keyboard; virtual touch on Recents
  opened the switcher, and Back dismissed it.
  [Phone Buttons](evidence/visible-recents/phone-buttons-ready.jpg).
- Tablet Gestures: four dock buttons with OSK including Recents; tapped Recents
  to open, tapped it again to close, and tested bottom swipe-and-hold.
  [Tablet dock](evidence/visible-recents/tablet-gesture.jpg).
- Tablet Buttons: six buttons. Tapped Recents to open and Back to dismiss.
  With a Foot window on the active workspace, bottom reservation changed
  `[0,48,0,84]` to `[0,48,0,0]`; virtual touch at the bottom edge revealed
  the dock above Foot and a Recents tap opened the page. More than five seconds
  later the page was still present and reservation stayed zero.
  [Open after timeout](evidence/visible-recents/tablet-open-after-timeout.jpg).
  The split action remained present in Tablet Recents and absent from Phone.
- Narrow Tablet Buttons: scale 4 yields 320 logical width; collapsed layer
  `x=16,y=116,w=288,h=84`, **one row**. Dock content is at least
  `6*48 + 5*4 = 308` logical px plus frame padding, so it overflows and
  horizontal virtual-touch flick reveals Recents. A subsequent touch on the
  scrolled Recents opened the page (`x=12,y=64,w=296,h=136`).
  [Scrolled dock](evidence/visible-recents/narrow-flick2.jpg),
  [tap opened page](evidence/visible-recents/narrow-open.jpg).
  The 200px logical height makes page content too short to use; the test is
  specifically for dock scroll/touch geometry, not narrow-screen page usability.
- Desktop single regression: full-width taskbar layer `x=0,y=736,w=1280,h=64`,
  bottom reservation 64, no touch gesture layer.
  [Desktop](evidence/visible-recents/desktop-regression.jpg).

Screenshots inspected before publication: Recents glyphs render, the dock stays
one row at 320px, no compositor error banner. `hyprctl -j configerrors` was
empty. Quickshell reported missing optional VM network backend, nightlight,
brightness, UPower and render-device fallback; configuration loaded.

## Guest restoration and remaining gaps

Installed shell tree was backed up before deployment because it predated the
integrated code and had unrelated changes; a staged complete shell tree was
installed via atomic per-file replacement, with `shell.qml` last. Atomic rename
alone did not trigger the watched file's reload; touching the now-installed
`shell.qml` did, without changing the process PID. Mode/navigation setting
changes did not take effect on that live reload, so the **VM only** shell was
restarted between preference modes; its original three Foot clients survived.
No ASUS device was touched.

After the pass, every installed file SHA256 matched the backup (131 files),
`shell.ini` was byte-identical (`cmp` exit 0), and monitor width/height/scale/
transform/position/active workspace/reservation matched the captured original
(`1280x800`, scale 1, transform 0, workspace 7, `[0,48,0,76]`). The test Foot
was closed; original Foot PIDs 829, 5305, 5437 survived. Restored shell loaded,
compositor configerrors was empty. Guest test scripts and raw captures are
untracked and not required to continue.

## Installed integration — atomic live reload

The parent integration matches the VM-accepted shell/session source exactly.
Combined checks passed: 227 Python tests (one skip) and 88 Qt tests. Before
deployment, both live files matched their previous known source hashes, so no
manual edits to those files were overwritten. All 130 shell-file backup hashes
and copied preference bytes were verified before replacement.

Installed `LayoutPolicy.js` first, then `shell.qml`, through same-directory
atomic replacement and touched the entry point to trigger normal live reload.
The source overlay is recorded in the device's live-source manifest on top of
shell package 0.1.0-9; it is not a package version upgrade. No watched-file
removal, shell restart or compositor config reload was needed. Shell PID 5842,
Foot PID 5945 and Discord PID 5980/window addresses remained unchanged. Journal
confirmed Configuration Loaded and compositor configerrors stayed empty. The
real-device screenshot showed portrait Discord with OSK and the status bar,
without an error banner; it did not exercise tapping the revealed dock.

**Remaining:** physical touchscreen tapping of Recents is not yet verified;
button/gesture acceptance is the actual VM touch evidence above. The 320px
proof used a 320x200 logical scale-4 dock, not a usable portrait-page test.
Existing #63 split drag/ratio, XWayland and multiple monitors were not retested.
#65 is already integrated/deployed. Next queued report is #69 Desktop app-menu
keyboard access. Review the independent branch or public `verify/visible-recents`
for the VM-tested combination; public integration includes the hardware overlay
source. Do not replace that source using a raw package refresh without preserving
it; the package watch-removal race is tracked separately as #75.
