# Honest status indicators (#73)

Scope: correct the existing status presentation without replacing communications,
network or power backends. Preserve dimensions, touch targets and click/focus
behavior. Unavailable cellular must never imply reception; normalized reported
strength must select a corresponding glyph. Battery presentation must show level
and actual charging, with an explicit unavailable state and accessible detail.

Based on current upstream main, independent of #71 / PR #87. Coordinate with
PR #68 (native Wi-Fi binding) and #54 (networking backend): neither is a dependency;
this change preserves existing backend ownership and does not implement network
configuration. Wi-Fi measurement remains a separate integration where unavailable.

Acceptance: focused regression RED/GREEN, safe constituent checks, and actual
before/after offscreen Qt Quick software rendering. No compositor verification,
GPU/desktop activity, VM/device deployment, package installation or personal
configuration changes. Hardware/service transition acceptance remains outstanding.

Status: implemented in draft PR #88. Existing cellular device/service flags now
gate reception; normalized signals select five levels without a fabricated
fallback. Battery glyph shows level and actual Charging, with explicit unknown
data and accessible/hover detail. Both shell locations pass ready/presence/state.
No backend replacement or geometry change.

Actual verification: focused RED/GREEN; 103 offscreen/software Qt results,
26 relevant Python tests (one skipped for missing GI), QML lint exit 0 with
integration metadata warnings, Bash and Lua syntax passes. `check.sh` was not
run because its compositor verifier is forbidden in this scope. Fish/ShellCheck
are unavailable; desktop validation has only the documented DesktopNames
diagnostic. See [testing record](testing.md#honest-status-indicators-73-2026-10-22)
and [before/after fixture capture](evidence/issue73-status-before-after.png).

Next: owner review followed by separately authorized device/service transition
acceptance. Native Wi-Fi measurement remains PR #68's separate integration;
reconcile signal/status overlap with #54 when either branch is integrated.
Keep this PR draft; nothing was deployed and #73 remains open.
