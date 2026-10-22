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

Status: scope published before implementation. Next: inspect installed metadata,
add regression cases, implement presentation and record actual results in
`docs/testing.md`. Keep this PR draft for owner review.
