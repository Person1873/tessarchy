# Application lifetime independent of shell — issue #72

Verified regression: systemd's default KillMode=control-group stops applications
launched inside tessera-shell.service. Quickshell.execDetached does not escape
that cgroup; the device showed Foot/Fish and Discord in the shell's cgroup.
Forking or exec alone is not an isolation mechanism.

## Scope before implementation

Use independent systemd user application units/scopes for app launches, preserving
argument boundaries, working environment, normal session shutdown and useful
logging without inheriting shell output lifetime. Keep supervision of the shell
and its own helpers. Do not weaken KillMode globally as a substitute for ownership.
Coordinate with runtime PR #62, which introduces shell service supervision.

QML changes should normally use Quickshell live reload, not process restart.
Verify reload success, unchanged shell PID and surviving apps. Still prove app
survival across a deliberate restart and crash in the VM, because live reload
alone cannot fix app ownership on failures. The Discord write EIO connection is
unverified and must not be presented as established.

## Acceptance / takeover

Publish the minimal fix, focused tests and full integrated checks. In the VM,
launch real apps through the shell, inspect independent cgroups, verify unchanged
app PIDs/windows across QML live reload, shell service restart and shell failure.
Check output lifetime and preserve safe session cleanup. Back up and restore the
VM files/settings atomically. No ASUS mutation or restart during development.

Current state: scope only. Next inspect launch paths and systemd execution docs,
implement against current upstream architecture, then integrate with #62/#63/
#64/#67/#68. Preserve native Wi-Fi recovery and the Desktop gap fix. #66 Recents
button follows this regression repair. Public PR must hold actual evidence and
remaining gaps so another contributor can take over.
