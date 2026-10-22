# Package-safe active source (#75)

## Problem and source contract

Package-owned payloads are currently active watched sources:

- `packaging/tessera-shell/PKGBUILD:15–17` copies QML into the live tree.
- `packaging/tessarchy-session/PKGBUILD:15–20` installs the Lua entrypoint and
  adjacent dependencies there.
- `session/tessera-shell:3–9,21` selects that QML pathname for startup and IPC.
- `session/start-tessarchy:10–13,26–29` exports the data directory and starts
  Hyprland against its Lua pathname.

Staging a package archive does not stop the package manager from removing the
old installed files before extraction. Moving payloads to versioned package
paths alone also fails: the old package manifest still owns/removes old paths.
A post-transaction restoration is too late for a running watcher.

The complete dependency closure matters, not just two entrypoints: adjacent
`window-controls.lua`, relative QML/Python imports and ringtone assets, hypridle
configuration and generated wallpaper references. Static `0.1.0` dependency
versions do not establish matching payload content across package releases.

## Bounded proposed implementation

1. Package complete candidates plus content/compatibility manifests, separately
   from active watched source. Validate a coherent candidate before publication.
2. Make actual copies into a non-pacman-owned, session deployment area. No active
   source or lazy dependency may resolve back into package-managed candidates.
3. Give each session stable regular QML/Lua bootstrap pathnames and stable IPC
   identity. Stage immutable complete generations; each bootstrap pins one exact
   retained generation. QML component wrapping needs a real software-Quickshell
   prototype before committing to a particular loader arrangement.
4. Activate explicitly, in-process: Quickshell `reload(false)` with generation
   acknowledgment and reload success/failure; compositor config-only reload with
   checked configerrors. Never call session startup or restart services as an
   activation mechanism. Two processes do not switch simultaneously: specify
   compatible sequential activation and rollback, not cross-process atomicity.
5. Retain all referenced generations until logout initially. Preserve explicit
   development-source selection, installed local modifications and preferences;
   do not silently replace a modified deployment with a stock package tree.

Installed Quickshell metadata exposes `reload(bool)`, `watchFiles`,
`reloadCompleted` and `reloadFailed`; shellRoot/shellDir are readonly constants.
[Upstream API reference](https://quickshell.org/docs/v0.3.2/types/Quickshell/Quickshell/).
A successful copy, atomic symlink switch or mtime change is not an activation
acknowledgment. Per-file atomic writes alone permit mixed-generation imports.

## Migration decision required before implementation

An already-running legacy session retains its original config pathname and
environment. Updating a launcher or systemd environment does not retarget it;
no supported in-process root-retarget API has been established. A guard installed
by the first transaction cannot be assumed to protect that same transaction.

The bounded safe proposal is a voluntary, one-time logout before adopting the
new launch contract, then in-process live upgrades on subsequent sessions.
Detect/refuse destructive upgrades of active legacy-owned sources, including
plain pacman paths, rather than killing apps or claiming transparent migration.
A zero-logout bridge is separate design work requiring actual package-manager
proof. This migration trade-off needs owner agreement before implementation.
No restart, package upgrade or runtime-path migration on the reference device.

## Acceptance plan

- RED: scratch-only file removal/replacement reproduces legacy missing sources;
  mixed-generation and symlink-retarget controls reject incomplete guarantees.
- CPU-only GREEN: stable startup/IPC paths; complete-generation coherence;
  validation/activation fault injection; rollback; locking; retention; local-edit
  refusal; helper, theme and wallpaper resolution; legacy-upgrade refusal.
- Private software-Quickshell: stable PID, import/helper resolution and real
  reload acknowledgments/rollback. No compositor/GPU or personal-session access.
- Separately authorized VM acceptance: real package transactions with both
  watchers active, repeated upgrade/downgrade/interruption, unchanged process/app
  identities, no missing-file/parser errors and functional IPC/screenshots.

## Boundaries and dependencies

Independent branch from current upstream. #72/#74 app-lifetime work is related,
not an excuse to restart a legacy shell. Preserve #71/#73 and other installed
integration differences when eventual deployment is prepared; this branch is
not a replacement image for the reference device. No #77/native shutdown work,
plugin build/load, scaling, OSK gesture or touchpad changes. No host/system or
personal configuration changes. No native, VM or device package tests in this
scope-publication checkpoint. Keep #75 and the draft PR open.

AI-assisted source review and scope; implementation awaits the migration decision.
