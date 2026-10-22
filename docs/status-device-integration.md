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

## Device result, 2026-10-22 UTC

Integrated topic PRs #87 and #88 while preserving the existing source integration.
The complete installed source matched the candidate except for four existing
status files and twelve new status dependencies/assets. Only those sixteen paths
were deployed; every other original source was readback-verified unchanged.
Full shell/session source and private preferences were backed up and verified on
both machines before writes. Dependencies preceded consumers; root was last.

Actual software verification: 151 Qt Quick results passed with offscreen/software
rendering. Selected status, power and communications Python suites passed (one
GObject metadata skip). No native compositor, VM, GPU or package-install test ran.

The live shell logged `Reloading configuration` then `Configuration Loaded`, with
no new warnings/errors. Shell, compositor and existing app identities survived;
compositor configerrors were empty. Private preferences stayed byte-identical.
Before/after captures were already in touch layout; no mode/scaling change occurred.

UPower reported 95% discharging before deployment and 92% discharging afterward.
The inspected actual bar showed 92% and a corresponding filled battery, without a
charging bolt. ModemManager had no system-bus owner; its CLI was unavailable.
Cellular now renders unavailable rather than invented reception. This is not a
hardware modem inventory or RF-strength acceptance. Native Wi-Fi binding and the
previous task-button source were preserved. Physical charging/unplug transitions
and modem RF testing remain outstanding; the topic PRs remain draft/open.

Full live screenshots, cropped review images, backup manifests and readback/log
receipts are retained privately under ignored `build/device-acceptance/`; no
personal-app screenshots or preferences have been committed or published.

Readback source SHA-256:

- `shell/shell.qml`: `ae50bfa16d4e11de3a5673a0e647e826b204a31359b5af8d93bc96fb00226cb0`
- `shell/components/StatusIcon.qml`: `2e34572e934ba73a3e5e2a64bbdb5818f21e266982cfe04de484a1ca963397f2`
- `shell/components/StatusIndicators.qml`: `2dd40e348acc2fdeecf78d797958b78db3657e88dc95988d17b8b14682fc8835`
- `shell/components/qmldir`: `efb8db8e2bf32daba47496b33c442ff63239863bcadef970ae31f683229f1ab0`
- Preserved `shell/components/TaskButton.qml`: `0cb48ad3d9bf470fee4ff025fb77895a3ab1102b481d4e7f7f197187ddbffc75`
