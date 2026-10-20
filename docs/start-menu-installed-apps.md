# Start menu: installed applications and automatic refresh

## Problem

Installed graphical applications can be missing from Start. The menu is labelled
"ALL APPS", but `shell/shell.qml` supplies `Apps.majorApplications(...)` from
`shell/AppPolicy.js`. That policy accepts only a fixed list of desktop-entry IDs
and selects one installed application per role. An application outside that
list is excluded; a second browser or terminal can also be excluded.

PR #2 introduced desktop-entry discovery and is already merged. It does not
resolve the current role-filtering limitation or cover the requested live-update acceptance checks.
The missing-app report has not been reproduced on a physical device here.
The code-level exclusion above is confirmed by inspection of current main.

## Requested behavior

- [ ] Show every installed, launchable graphical application that is eligible
  for the current desktop session, including applications outside the primary
  role list and multiple applications in the same role.
- [ ] Keep any curated primary-app selection separate from the complete All Apps
  inventory. Do not label a curated subset "ALL APPS".
- [ ] Use Quickshell's built-in desktop-entry monitoring and application model
  updates to keep Start current. No periodic polling timer or custom rescan on
  opening Start is required. Verify change propagation on the supported version.
- [ ] Add newly installed applications without requiring logout or a shell
  restart; remove uninstalled applications and update changed names/icons.
- [ ] Present applications in a clean, consistent layout: clear category
  headings from desktop-entry metadata, alphabetical ordering within categories,
  and an Other category for applications without a recognized category.
- [ ] Keep all eligible applications reachable when many are installed:
  scrolling, readable labels, consistent icon sizing and spacing, keyboard
  navigation, and touch targets at least 48 logical pixels.
- [ ] Preserve desktop-entry visibility rules and precedence. Respect Hidden,
  NoDisplay, OnlyShowIn, NotShowIn, and TryExec where supported by the discovery
  API. Deduplicate by desktop-entry identity, not display name; preserve separate
  applications with the same name.
- [ ] Include standard system and per-user application locations and supported
  Flatpak/Snap export locations through the session's XDG data directories.
  Terminal-only packages without desktop entries need no launcher tile.
- [ ] Launch through the desktop-entry execution API; do not construct shell
  commands from names or Exec strings. Handle missing icons and entries removed
  during refresh without breaking the menu.
- [ ] Keep refresh asynchronous and inexpensive. Do not query package managers
  repeatedly or rebuild an unchanged menu. Preserve scroll position and keyboard
  focus across background updates where possible.

## Acceptance checks

1. Open Start, install a graphical application outside the current role list,
   and confirm it appears after Quickshell reports the desktop-entry change,
   without restarting the shell. Repeat with Start closed, then reopen it.
2. Install two browsers or terminals and verify both appear in All Apps.
3. Uninstall an application while Start is open; verify its tile disappears and
   attempting to launch a stale selection fails gracefully.
4. Add, change, hide and remove a per-user desktop entry. Verify its name, icon,
   visibility and launch behavior update correctly.
5. Verify duplicate system/user desktop-entry IDs honor user precedence,
   including a user Hidden override; unrelated equal-name apps remain visible.
6. Verify supported Flatpak/Snap entries appear when their export directories
   are available to the session.
7. Verify categories, alphabetical ordering, missing-category/icon fallback and
   a large inventory. Check keyboard and touch navigation, long labels, scrolling
   and narrow layouts wherever the shared app inventory is used.
8. Confirm repeated application-change events do not duplicate entries, move focus unnecessarily,
   block interaction, or noticeably increase idle resource use.
9. Run `./scripts/check.sh` for the implementation. Add regression coverage for
   unrestricted eligible-app discovery, filtering/precedence, ordering,
   additions/removals and refresh lifecycle; record actual VM/device results in
   `docs/testing.md`.

## Scope and status

This PR records the issue, requested behavior and acceptance plan. It does not
implement a runtime fix or claim successful installation/refresh testing.
Implementation should use an isolated branch based on current main and preserve
existing Start styling and unrelated work. Hermes's unmerged theme work is
outside this change.

Validation for this tracking document: checked the current AppPolicy.js through
GitHub, reviewed its Start-menu use and the existing merged PR #2, and confirmed
the checklist distinguishes requested behavior from verified code observations.
