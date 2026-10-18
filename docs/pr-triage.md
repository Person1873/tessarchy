# Pull request review — 2026-10-18

## Update — easiest-PR pass complete

The three smallest genuine integrations are merged: **#21** idle blanking,
**#22** display rotation and **#13** notification center. #16 window previews is
confirmed **superseded** by the current AppSwitcher (its grid would replace the
card switcher); closing it is the resolution, not a merge. Still open: **#23**
Wi-Fi, **#19** brightness/night light (fix the unguarded PID kill first), **#12**
tablet split, and the **#9 → #10 → #11 → #20** theme/portal/keyboard stack. The
original ranking below is retained for reference.

The existing PRs were rescanned after the Phone/Messages checkpoint.
Order reflects integration effort and product risk against the current shell.
The owner authorized skipping disruptive or difficult work.

| Order | PR | Decision | Current reason |
| --- | --- | --- | --- |
| 1 | #18 Power panel | Integrated | Added missing-service and supported-profile guards, authoritative readback, unavailable battery state and tests. Preserved current app UI and manifest-based uninstall. |
| 2 | #21 Idle blanking | Defer | The branch now uses Lua DPMS correctly. Integration still changes session startup and capture wake input; hypridle is absent in the VM and blank/wake/PIN acceptance needs a dedicated test. |
| 3 | #23 Wi-Fi | Defer | The updated branch includes PSK entry and scanner handling. It replaces the image's wired network service; device replacement/scanner ownership and NetworkManager/keyboard association still need acceptance without losing connectivity. |
| 4 | #22 Rotation | Defer | The updated helper now writes Lua and attempts rollback. Monitor parsing, preserved settings and touch-coordinate recovery still affect the display path; avoid changing it during this app checkpoint. |
| 5 | #13 Notifications | Defer | A new D-Bus notification server, history and popup lifecycle need reconciliation with current layered panels and native phone alerts. Keep this as a focused integration. |
| 6 | #19 Brightness/night light | Skip for safety | The night-light helper still trusts kill -0 on a PID file, then kills that PID without checking process identity. Brightness also needs real backlight/permission validation. |
| 7 | #16 Window previews | Skip as superseded | Current card previews already implement the requested switcher. The old shell/grid patch would replace current UI behavior. |
| 8 | #9 System theme | Defer | Broad shell/application/keyboard changes across49 files. Existing unfinished review in build/integration is preserved. |
| 9 | #11 Keyboard sizing | Defer dependencies | Its current diff includes the theme/portal stack across58 files. The narrower-width/48px-height exception is already authorized; extract sizing after its dependencies are reviewed. |
| 10 | #20 Keyboard page guard | Defer dependencies | Current shell already hides the keyboard when opening pages/controls. This59-file stacked branch includes theme/portal/keyboard changes that need separate review. |
| 11 | #12 Tablet split | Defer | Layout, focus and workspace transitions would substantially change current navigation and the card switcher. |
| 12 | #10 Third-party file dialogs | Defer | A57-file theme/portal stack includes new C and GTK IPC, cancellation and overwrite paths. Tessera's new in-panel browser solves its own photo/tone selection without merging that wider portal stack. |

PR #28 (remove the live-boot NTP gate) is integrated. Its contributor commit
is preserved as a merge parent. A staging regression check asserts removal of
the inherited time-wait link, and Alpha 3 reached Tessera in BIOS and UEFI with
no network adapter.

Eleven previously reviewed PRs remain open. Their branches and original commits
are preserved, including the unfinished theme review in `build/integration`.
Actual checks and device acceptance remain in [testing.md](testing.md).
