# Touchpad tap-to-click — issue #81

## Scope published before implementation

Investigate the reported missing tap-to-click behavior on the ASUS dogfood
session. The recorded global Hyprland option is already true and not explicitly
set; adding the same global value is not a demonstrated solution.

First inspect shipped defaults, per-device override precedence, running device
inventory and libinput capability/default reporting. Separate a compositor's
current libinput handle state from a separate diagnostic context's defaults.
A fresh libinput context does not report the running compositor's configuration.
Do not treat synthetic pointer-button injection as proof of touchpad tapping.

No cause or implementation selected yet. Publish actual findings before changing
input policy. A device driver/compositor change or a need to capture real input
requires a separately bounded plan; no native builds, package installation,
input injection, physical-device configuration changes or session restarts are
part of this initial read-only investigation.

## Dependencies / overlap

Independent of #80/PR91's new OSK overflow placement feature. That feature now
has bounded live geometry/input acceptance. #77/PR83 native scaling and shutdown,
#82 scaling defaults, and #75 runtime-copy/update-policy expansion remain parked.
No equivalent touchpad implementation was found among current open PRs.

## Verification plan

- Read actual target Hyprland Lua/config and libinput API documentation.
- Check device capability and override paths without recording unrelated input.
- Add focused tests only once an owned behavior/cause is established.
- Preserve settings, running apps and original compositor/shell processes.
- State unresolved measurements explicitly rather than substituting defaults
  or a fresh diagnostic context for actual running-handle state.

AI-assisted investigation.
