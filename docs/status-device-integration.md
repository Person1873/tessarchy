# Status presentation device integration (#73)

Scope recorded before integration. Continue PR #88's existing status presentation
work with live acceptance on the reference laptop. Preserve the already-deployed
vertical task-button fix from PR #87 and all prior integration changes.

Base: public `sync/upstream-20261021`. Its root shell source hash matches the
installed shell observed before this work. Integrate PR #87 and PR #88 in this
branch, but deploy only the status presentation files after comparing the complete
installed source snapshot against the integration tree. Back up and verify the
installed shell, session sources and private preferences before changes.

Use staged dependencies and per-file atomic replacement, root shell last, then
verify an in-process configuration reload. Do not restart the shell/compositor,
change layout or scaling, disturb running apps, install packages, or run native
compositor/GPU workloads. Preserve native Wi-Fi measurement and existing app
lifetime isolation. Inspect real read-only ModemManager/UPower observations and
actual screenshots; never substitute fixture values for hardware observations.

Charging/discharging transitions requiring physical power changes and modem RF
accuracy cannot be established from one connected, modem-less device snapshot.
Keep those acceptance gaps explicit. Keep the topic PRs separate and draft;
deployment is not upstream acceptance. No work on parked native fitting/shutdown.
