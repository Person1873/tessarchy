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

## Status and takeover

Scope only, published before code. Implementation follows completion of #65's
integrated acceptance/deployment in FIFO order. Next: adjust Recents visibility
without restoring unwanted extra navigation buttons, add regression coverage,
then test the integrated runtime and publish evidence before device rollout.
