# Direct OSK dismissal — issue #89

## Scope published before implementation

Add one discoverable glyph button while the OSK is mapped in Phone or Tablet
mode. It must dismiss the keyboard directly, without opening the navigation
pill/dock, closing the app or submitting/discarding text. Button touch target
at least48x48 logical pixels; preserve the text field's keyboard focus.

Selected implementation route: a separate shell layer with only the button's
input region, immediately above the keyboard's right edge. Do not cover keys or
the physical-bottom navigation strip. Show only for a mapped `osk` layer on the
same output; availability alone is insufficient. Keep Desktop unchanged. Use
theme tokens and an accessible name. Existing `tessarchy-osk hide` supplies the
hide action; no new Squeekboard native action, raw key binding or YAML keymap
modification. Upstream Squeekboard's `Action` enum has no direct Hide action.

First verify installed Quickshell APIs and per-output layer coordinate handling.
Keep geometry decisions in a small testable policy, not duplicate magic numbers.
No background keyboard show/hide loops and no app focus grabs. Remove the layer
when the keyboard closes. Handle monitor origins and insufficient free space
without placing a target over typing keys.

## Dependencies / overlap

Based on current upstream main; no equivalent open implementation found.
Coordinate #78/PR79's physical-bottom reserved gesture strip; do not alter that
strip. #80/PR91 placement feature is independent but benefits when dismissal
restores a lifted dialog. #81 investigation found an active tablet-mode switch
and needs further measurements; no speculative tap setting change is selected.
#82 scaling and #77/PR83 native scaling/shutdown remain parked.

## Acceptance

- Focused policy/component checks: Phone/Tablet, mapped/unmapped/wrong-output
  keyboard, Desktop unchanged, origins, rotation/scale and small-space bounds.
- Hide request exactly once from the button; no text submission or app closure.
- Verify button stays outside keyboard and bottom gesture input region.
- Live acceptance must inspect screenshots and delivered touch through a
  disposable app, confirm text unchanged and continued typing after reopening.
- Software rendering and isolated CPU tests first. No host desktop changes,
  native builds, package installs, personal-app input or service restarts.
  New live-device actions require their own bounded authorization; prior #80
  device acceptance is not claimed as #89 verification.

AI-assisted feature implementation and verification.
