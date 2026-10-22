# Runtime/source identity report (T04)

## Scope published before implementation

Branch `feat/runtime-identity-report`, from current upstream main. Independent
of screenshot/OSK drafts. No equivalent runtime-identity helper found among the
current open PRs or existing scripts.

Add an opt-in, read-only developer script and capture checklist. Identify one
running Quickshell process by explicit PID or the existing Tessera service's
MainPID; derive its source from that process's actual `--path`/`-p` argument.
Do not infer the running source from launcher defaults, a checkout or a package
version. Unresolvable/ambiguous selection is unavailable, not a guessed root.

Record source kind, disk source hashes and optional Git identity; selected
process/service state; bounded version queries; numeric monitor geometry and
scale/transform. Distinguish installed disk bytes from loaded QML state: the
report cannot prove which bytes a prior reload committed.

Exclude client titles/content, environment dumps, credentials, network endpoints,
monitor serials/descriptions, absolute source/home paths and raw command errors
from the JSON report. Use only fixed read-only command arguments, bounded calls
and ordinary source reads. No source/config writes, reload/restart, input,
notifications, capture, package changes, update-policy work or native builds.
This is a developer checklist/tool, not an installed session dependency.

## Verification

CPU tests with controlled process/source trees and command replies: explicit
selection, service selection, source arguments, missing/dead/ambiguous state,
version/query failure, timeouts, geometry filtering, source hashing and privacy.
Exercise `--help` and a real read-only Tessera process report when available;
keep fixture and actual-device observations separate. Run available repository
checks. Publish commands/evidence and keep draft pending unexercised cases.

## Status

Scope only; implementation and actual execution results follow here and in
`docs/testing.md`.

AI-assisted contribution.
