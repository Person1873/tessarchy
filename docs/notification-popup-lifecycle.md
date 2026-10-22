# Notification popup lifecycle (T06 subset)

## Scope published before implementation

Branch `fix/notification-popup-lifecycle` from current upstream main. Existing
open notification-related changes were checked; PR94 concerns the screenshot
helper, not popup ownership. This change is independent of other draft features.

Current `shell/shell.qml` keeps popup objects in a separate array (lines 186–220).
New deliveries unconditionally prepend; popup timers/user dismissal remove
entries, but application withdrawal/removal from the tracked model does not
(lines 1328–1369). A replacement delivery can therefore queue the same object
again, and a withdrawn alert can retain a popup slot until its timer fires
(or indefinitely for an urgent alert without a popup timeout).

Keep the server's tracked model as history truth. Make the ephemeral popup queue
follow model removal and deduplicate replacement delivery by object identity.
Preserve newest-first order, the three-popup limit, body-tap versus close
semantics, existing timeout policy, DND delivery suppression and non-focusable
popup windows. Never requeue an older alert merely because a newer one closes.
No expiry/history-policy change, source-generation/update work, native builds,
ASUS deployment/input, service restart, package or VM lifecycle changes.

Extract the existing queue behaviour into a small ordinary Qt component so real
queue logic and model-change connections can be exercised without a live
notification bus. Installed `Quickshell/ObjectModel` metadata exposes
`valuesChanged`; no generic QML signal guessing is required.

## Acceptance and verification

RED-first controlled Qt objects/models for: replacement deduplication, app
withdrawal, urgent withdrawal, bulk removal, three-item overflow/order,
body-hide retaining history, close/removal retaining other alerts, no old alert
resurrection and empty/no-op removals. Exercise actual production component,
not only a reimplemented policy. Run current Qt and repository checks; document
actual results separately from later bus/UI acceptance. Remain draft while
unexercised live cases remain. No personal desktop capture.

## Status

Scope only. Implementation and actual results follow in this document and
`docs/testing.md`.

AI-assisted contribution.
