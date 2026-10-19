# Pull request review — 2026-10-19

Review order prioritizes bounded changes and preserves contributor commits. PR #52
integrated the first four entries into main; its combined checks and follow-up
fixes are recorded in docs/testing.md. GitHub mergeability and CI
status are snapshots, so refresh them before the next integration.

| Order | PR | Review result / next action |
| --- | --- | --- |
| 1 | #51 QML lint | Integrated into main: unused imports, night-light process name and typed audio loader. Combined source checks passed. |
| 2 | #44 Desktop taskbar polish | Integrated into main: task overflow, Start menu and consistent indicators. Preserved its commits and tests. |
| 3 | #45 Icon-only Alt+Tab | Integrated after #44 through #52; the original stacked PR was closed after verifying its head is an ancestor of main. Kept compact desktop spacing and the separate touch Recents switcher. |
| 4 | #48 Shared navigation geometry | Integrated after #45. Resolved shell geometry against current desktop spacing; retained both testing records. Added explicit non-stretching dock/taskbar rows. |
| 5 | #46 Window controls and live installer | Separate review. Its scope now includes disk installation and boot branding. PR #53 merged T74 fail-closed live-medium/mounted-target/kernel checks into its feature branch, with mocked destructive operations; installed-disk and fresh-image acceptance remain separate. PR #55 reconciles its history with current main and the tested phone work; installed-disk acceptance remains pending. |
| 6 | #38 ARM development VM | Conflicts with main. Reconcile VM scripts in isolation, validate downloads and source sharing, then boot the ARM guest. An emulated guest is not phone hardware acceptance. |
| 7 | #23 Wi-Fi association | Conflicts with main. Rework against current controls and NetworkManager setup; accept scanner ownership, credentials/cancellation, device/service replacement and keyboard entry before integration. |
| 8 | #9 System themes | Broad foundation for #47/#50 and part of the portal stack. Current CI fails: Ubuntu lacks QtQuick.Effects for MediaPanel/PinScreen, and Arch ShellCheck rejects terminal-escape printf strings (SC1003). Fix the declared Qt dependency and shell formatting before reviewing runtime theme behavior. |
| 9 | #47 Theme shapes | Depends on #9 and inherits failing checks. Review the data parser, limits, generated compositor values and reset behavior after the theme foundation works. |
| 10 | #50 Theme extras | Draft, stacked on #47/#9, checks failing. Keep icon/theme changes and default-off borders isolated until dependencies pass. |
| 11 | #49 Navigation gestures | Draft, stacked on #48. Reconcile against the combined shell, preserve the buttons fallback, then test edge interception, cancellation, scaling and real touch. |
| 12 | #20 Keyboard page guard | Draft. Extract only behavior missing from current focus/page guards; test open/close transitions and retained text focus without importing unrelated stack changes. |
| 13 | #12 Tablet split | Draft. Needs a focused two-app focus/restore/mode-transition review after navigation stabilizes. |
| 14 | #10 Touch file dialogs | Draft. Current Arch logs show missing GTK3 development metadata/headers during build and ISO staging tests. Fix declared CI/build dependencies, then review portal IPC, cancellation, overwrite and fallback behavior separately. |

#16 is already closed as superseded. Power, idle blanking, notifications,
rotation and brightness/night light are already integrated; the previous
contradictory defer/skip table has been removed. The unfinished theme worktree in
build/integration remains untouched.

The audit fixes literal rendering of external text, page-expansion layout,
website activity/release handling and publication source. Actual hardware,
visual browser, new ISO boot and installer acceptance must not be inferred from
static checks. See docs/testing.md and docs/live-install.md on the installer branch.
