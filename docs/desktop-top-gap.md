# Desktop unused top space — issue #65

## Report

The owner reports a large gap above open windows in Desktop mode. The issue's
ASUS capture shows unused wallpaper above Discord, with reservations
`[0,48,0,64]` at scale 1.5. This establishes the current window and reservation,
not the cause or behavior of all applications.

## Scope before implementation

Reproduce and diagnose the Desktop top gap, then correct the source responsible
for unused reserved space or inappropriate window placement. Preserve intentional
visible UI, useful top-bar controls, Desktop taskbar behavior, and Phone/Tablet
layouts. Do not assume the 48 px top reservation itself is erroneous without
checking which surface is actually rendered there.

## Verification and coordination

Inspect actual layers, reserved regions and client bounds, compare upstream main
and the public integration branch, then add a focused regression test and run
the full checks. Validate screenshots on the VM in all three layouts before a
hardware update. Coordinate shell.qml changes with #63/#64. #66 (visible Recents
button) is next in the owner's FIFO queue; do not implement it in this fix.

## Diagnosis and implementation

On the QEMU guest at 1280×800, Desktop showed a 48-pixel wallpaper strip above
Foot (both tiled clients started at y=48). `hyprctl layers -j` reported the
`tessera-status` layer at (0,0) size 1280×48 and the taskbar `tessera` at
(0,736) size 1280×64. The monitor reserved region was `[0,48,0,64]`. The
installed older shell *did* paint workspace buttons, a clock and weather in
that top strip; removing the reservation on that version would hide useful UI.
The upstream main shell instead moves Desktop indicators, weather, quick-launch
and the clock into the bottom taskbar. Its Desktop top status surface has no
visible contents when collapsed, yet still maps and reserves 48 pixels. The
integrated e4722ae (#62/#63/#64) retains the same top status surface and
reservation; its changes to the bottom dock do not address this cause.

The fix leaves the Desktop top sheet unmapped while collapsed and assigns it
no exclusive zone in Desktop, including when expanded. Opening the sheet via
`controls.toggle` or the Settings page still maps it as an overlay. Phone and
Tablet continue mapping and reserving 48 pixels for their visible status UI.
The bottom Desktop taskbar remains reserved and retains its tray controls.

## QEMU verification

Executed in the running guest with a backed-up installed shell and shell.ini.
Source files were staged via scp then replaced atomically per file; no session
config was removed. Screenshots (1280×800):

- [Older installed shell with visible top controls](images/issue65/issue65-before-desktop.png)
- [Upstream main before: unused strip](images/issue65/issue65-main-before-desktop.png)
- [After: Foot reaches y=0](images/issue65/issue65-main-after-desktop.png)
- [After: Desktop quick sheet open](images/issue65/issue65-main-after-drawer.png)
- [After: Tablet status and dock](images/issue65/issue65-after-tablet.png)
- [After: Phone status and dock](images/issue65/issue65-after-phone.png)

Before: Desktop `reserved=[0,48,0,64]`, Foot tiled bounds `(0,48)
640×688` and `(640,48) 640×688`. After: `reserved=[0,0,0,64]`,
Foot bounds `(0,0) 640×736` and `(640,0) 640×736`; status surface absent
until the sheet opens, at which point its 1280×724 overlay maps without
reserving the app area. Tablet `reserved=[0,48,0,84]`, Phone
`reserved=[0,48,0,76]`; both show top status controls and bottom docks.
All mode captures had empty `hyprctl -j configerrors`, and the shell stayed
running. `./scripts/check.sh`: 215 Python tests (one skipped), 4 site tests,
76 QML tests, two Hyprland configs parsed; existing lint warnings remain.

## Remaining validation

No ASUS device changes or measurements were made. Real hardware at scale 1.5,
other monitor arrangements, and the integrated branch after merge have not been
verified. Desktop's collapsed top-edge swipe/click target is intentionally
removed in favor of the taskbar/Settings and IPC entry points; confirm this
interaction choice with the owner before device rollout.
