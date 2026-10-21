# Automatic touch dock hiding

## Scope

Hide the bottom dock while application windows are open in Phone and Tablet,
reclaim its reserved space, and allow touch reveal over the application.
Preserve Desktop taskbar behavior and existing navigation choice. Keep the
gesture-handle preference separate from automatic dock hiding.

## Coordination

The dock geometry and horizontal-scrolling carry-forward in PR #63 must be
preserved when integrated. This change does not redesign dock contents, system
navigation or top-bar tools.

## Acceptance

- Hidden dock reserves no application space.
- Touch reveal remains reachable and overlays application windows.
- Shell pages retain usable navigation.
- Keyboard and split layouts do not acquire blocked controls.
- Desktop behavior is unchanged.

## Verification plan

Automated policy tests and VM touch/screenshot checks across Phone, Tablet and
Desktop; Buttons and Gestures; app/no-app and keyboard visible/hidden states.

## Current status

Scope only; implementation has not started and no acceptance check has passed.
Next step: inspect the current layer exclusive-zone and gesture routing before
choosing the smallest compatible implementation. Public checkpoints and PR
handoffs must identify actual tests and remaining gaps before device deployment.
