# OSK and bottom gesture input overlap — issue #78

## Scope published before implementation

The reported portrait Tablet keyboard rectangle ends at the output bottom,
while a higher-layer, full-width 16 logical pixel gesture strip occupies the
same bottom pixels. The visible pill overlaps the spacebar; lost key presses
are user-reported, not yet independently injected.

Inspect upstream/open PR equivalents, keyboard visibility/geometry discovery,
and bottom/side gesture input surfaces before choosing a fix. Resolve actual
input-region overlap, not only drawing. Prefer a coherent policy that keeps
keys fully accessible and navigation reachable without overlaying keyboard
keys. Preserve gestures when the OSK hides, Phone/Tablet Recents buttons,
auto-hide dock protection and Desktop behavior. No hard-coded theme colours.

Dependencies/overlap: shell.qml, gesture components/policies and tests;
coordinate #63/#64/#70 and current #76. Test the public integration combination
as well as the independent patch. No ASUS restart, config mutation or input
injection during development. Use QEMU with an exclusive test window; another
worker is currently using that VM and must finish/restore before this test.

## Acceptance

Add regression tests for keyboard shown/hidden and input regions. Real VM
touch at the formerly intercepted bottom spacebar must produce spaces in a
real editor, not navigate the shell. Verify actual layer rectangles, keyboard
hide restoring normal navigation, Phone/Tablet portrait and landscape, and a
Desktop smoke check. Inspect before/after screenshots. Preserve shell PID and
apps across normal live reload, and restore guest source/settings/monitor
byte-for-byte. Publish actual results, limitations and takeover commands.

## Owner decision (after scope publication)

Reserve a small, physical-bottom navigation strip so the compositor lifts the
keyboard *above* the input surface. Keep the visible gesture pill at the
physical bottom on an opaque black, theme-token background. Do not move the
strip above the OSK, clip keys, or infer visibility from OSK availability.
Use the existing gesture target dimensions as the reservation geometry and
retain the hidden-dock reveal target in Buttons mode. Verify the reservation
against real mapped layers and typed spaces in QEMU.

Current state: VM diagnosis in progress; no accepted feature implementation yet.
