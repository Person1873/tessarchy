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

## Current state and takeover

Scope only; no code changes or completed verification. Next: reproduce the
reported gap and establish its mechanism. Keep evidence and remaining steps in
the PR so maintainers can continue independently of local agent context.
