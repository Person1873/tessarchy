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

Scope published before implementation. Actual execution results will be recorded in docs/testing.md and the PR body.
