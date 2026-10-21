# Restore live Wi-Fi signal binding

The owner's working on-device shell used Quickshell.Networking to locate the
Wi-Fi device and read the connected network's measured signalStrength. A package
refresh overwrote that uncommitted live change with the upstream -1 placeholder.
The original implementation was recovered from the verified pre-update backup.

Scope: restore that same native Networking approach for the indicator, with safe
no-device/no-connection fallbacks and regression coverage. Do not introduce a
new connection manager or incorporate unrelated UI changes. Coordinate with #54,
which implements a broader networking backend using a different mechanism.

Current state: recovery identified; implementation not started. Next: verify the
installed module API, port the binding, test, then restore the indicator on the
real Wi-Fi device. Preserve and compare live edits before every future upgrade.
