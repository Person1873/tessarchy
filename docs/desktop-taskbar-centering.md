# Desktop taskbar selector centring

Addresses #71 independently of oversized-window fitting and native compositor repair.

## Scope

Centre the combined application icon and title within each Desktop task button. Preserve the existing button size, spacing, selected styling, focus policy, accessible name and window-activation action. Long titles must elide within the available width. Missing icons must not leave an empty icon column.

No compositor changes, application scaling, launcher redesign, device deployment or unrelated status-indicator work.

## Acceptance

- Short icon/title groups have equal horizontal space on both sides and are vertically centred.
- Long titles elide without clipping or displacing the icon outside the button.
- Iconless titles centre without a reserved icon gap.
- Selected, disabled and ordinary states retain their geometry.
- Focused Qt Quick regression tests exercise actual item geometry and title elision.
- Inspect software-rendered evidence without changing the running desktop.

## Verification

Scope published before implementation in `50c900e`.

- Unchanged upstream: all 18 short-title centring cases fail (no QML warnings).
- Fixed component: 23 Qt results pass, including centring, elision and activation.
- Full Qt Quick suite: 99 passed; Python: 214 run, one skipped; website: four passed.
- Changed-component QML lint and whitespace checks pass.
- Actual offscreen software-rendered before/after evidence was inspected; see
  [testing record](testing.md#desktop-taskbar-icontitle-centring-2026-10-22).

No compositor, VM, device deployment or running-desktop changes. Native scaling
and shutdown repair remain parked and are not dependencies of this fix.
