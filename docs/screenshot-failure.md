# Screenshot failure reporting (T03)

## Scope published before implementation

Branch: `fix/screenshot-failure-notification`, based on current upstream main.
No dependency on the touchpad investigation, native fitting, OSK or other drafts.
No equivalent screenshot-failure PR was open at scope time.

The existing screenshot helper removes partial captures and returns the capture
command's failure, but failure is only visible on stderr. Print and pull-down
launches need an optional desktop failure notification as well.

Implement a bounded change to `session/tessera-screenshot`:

- Keep unique private filenames, success output and existing optional success
  notification; reject unexpected arguments before attempting a capture.
- On dependency, destination preparation or capture failure, retain the original
  nonzero status and stderr, remove only the attempt's partial file, and emit one
  optional `Screenshot failed` notification with a fixed stage-specific reason.
- Notification absence/failure must not replace the capture result, print a
  saved path on failure, remove existing files or lose a successful capture.
- Do not include raw stderr or destination paths in failure notification bodies.

## Verification plan

RED-first subprocess tests with scratch HOME/config and controlled executable
fixtures; exercise actual helper control flow, file ownership/permissions and
notification arguments. Check missing dependency, mkdir/mktemp/capture failures,
success, optional/failing notification service and usage rejection. Preserve the
existing workflow cases. Run Bash syntax and the repository check script where
available. Fixtures are not compositor capture or desktop-notification delivery.
No host/device capture, input injection, service restart, package installation,
VM/GPU/native build, preference change or physical-sensor testing is in scope.

Live Print/pull-down framing and actual notification display remain separate T03
acceptance work, not claims established by helper subprocess tests.

## Status

Scope only. Implementation and execution results follow in this document and
`docs/testing.md`; this draft is not ready for acceptance.

AI-assisted contribution.
