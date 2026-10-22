# OSK overflow placement — issue #80

## Scope published before implementation

After a Phone/Tablet floating dialog receives a resize request, inspect its
actual resulting geometry. If it remains too tall to clear the visible keyboard,
move that window upward beneath the status bar, leaving the bar above the app.
Overflow beyond the status-bar height may place the top farther off-screen.
Restore the policy-owned placement when the keyboard closes; hiding the keyboard
must also make upper application content reachable again.

First verify the target Hyprland Lua layer/window/event APIs. A dispatched resize
is not evidence that a toolkit accepted the requested size. Do not treat a
compositor allocation as proof of the client's actual content dimensions.

Keep changes per-window. Preserve normal fitting dialogs, Desktop behavior,
fullscreen/tiling/split policy, monitor origins, rotation and fractional scale.
Do not remove top reservations globally, change app settings or scale application
content. Avoid repeated resize/move loops and do not overwrite a user's later
manual placement with stale saved coordinates.

## Dependencies and overlap

Base: current upstream main. Existing `session/hyprland.lua` fitting/refit events
and workflow tests. Coordinate #78 keyboard reservations and #89 dismissal.
PR83/#77 native fitting and shutdown remain parked and are not dependencies or
authorization for native work. No equivalent open #80 implementation was found.

## Verification

- RED-first isolated Lua tests with an asynchronous/rejected resize model.
- Cover successful resize (no lift), minimum-height overflow, keyboard hide and
  repeated events, moved/closed windows, multi-output origins, rotation and scale.
- Desktop/fullscreen/nonfloating controls must remain unchanged.
- Run applicable software/static checks. Do not launch a compositor/config
  verifier, compile native code, run VM/GPU tests or change the ASUS for this work.
- If the required Lua observable/event is absent, document that exact blocker
  rather than inventing an API or claiming a synthetic model is live acceptance.
- Actual compositor/touch/visual acceptance remains outstanding until separately
  exercised; source tests alone cannot establish the requested user behavior.
