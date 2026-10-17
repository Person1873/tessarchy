# Phone PIN sign-in

The owner selected a four-digit PIN as the Linux account password. This is a
pre-session greetd/PAM login, not a lock overlay inside Tessera. The login page
has the Quiet Edge wallpaper, Tessarchy mark, mobile clock, four masked dots,
glass numeric keys and an icon for deletion. The fourth digit submits once;
keyboard digits, Backspace, Escape and Enter are supported. Keys remain at least
48 logical pixels wide and tall; compact layouts scroll if needed.

`PinScreen.qml` handles entry without writing a PIN to disk. `PinLoginController`
creates a greetd session for the configured account, responds to exactly one
secret challenge, clears its pending value, and launches the fixed
`/usr/bin/start-tessarchy` command only after authentication succeeds. Visible
or additional secret challenges and passwordless success are rejected. Attempts
time out after 30 seconds. Failure clears pending input and delays retry for
three seconds; PAM remains responsible for system account policies and rate
limits. If cancellation cannot return the backend to idle, the greeter exits
and greetd can restart it. No PIN is put in command arguments, environment,
settings, logs or this repository. QML string copies are not claimed securely
zeroed in memory. Four digits have low entropy and do not replace system account
protection, encrypted storage, or device security review.

The separate greeter Hyprland configuration loads no user preferences or
application-launch bindings. It starts only the greeter. The launcher exits
that compositor when Quickshell exits, allowing greetd to start the authenticated
session. greetd uses its packaged PAM configuration; no custom PAM module or
permissive PAM stack is shipped. `source_profile=false` avoids login-profile
side effects before the explicit session command.

## Review and package layout

Preview only: `qs --path shell/login-preview.qml`. It explicitly says sign-in is
disabled and cannot launch a session. Do not describe a preview as authentication.
The actual entry point is `shell/greeter.qml`, launched through greetd.

`scripts/package.sh` now also builds the opt-in `tessarchy-greeter` package.
It depends on greetd and the normal Tessarchy session packages. It installs a
namespaced `/etc/greetd/tessarchy.toml`, `/etc/tessarchy/login-user`, the greeter
launcher/config, and a greetd systemd drop-in selecting that config. It does not
enable or start the service. It does not overwrite `/etc/greetd/config.toml`.
The public account-name file defaults to `tess` and contains no credential.

The existing ISO continues to use its locked live account and autologin. This
experimental greeter is not enabled in ISO staging: enabling it without a
provisioned account password would strand testers. Published Alpha 2 is unchanged.
First-boot PIN enrollment for disposable/live media remains future work.

## VM activation plan — not yet performed

1. Keep a VM snapshot and the current SSH connection/recovery TTY available.
2. After explicit owner permission, install greetd in the VM and the three local
   Tessarchy packages. No host package/configuration change is needed. Built
   candidate packages are under ignored `build/phone-login-packages-final/`.
3. Set `/etc/tessarchy/login-user` to `arch` for the current development VM.
4. Have the owner choose a four-digit account password. Set it directly in the
   VM through standard password tooling; do not save it in source, shell command
   arguments, transcripts, scripts or build images. Existing account-password
   recovery and PAM policy still apply. The current password must change before
   this numeric-only greeter can authenticate the account.
5. Back up and remove only the known development tty1 autologin override, and
   disable tty1 getty autologin. Preserve another recovery TTY. Check the package
   PAM stack, greeter account/home permissions and graphical default target.
6. Enable greetd for the next boot. Starting it immediately conflicts with tty1
   getty and can end the current session; get explicit confirmation before that
   session exit/reboot. Preserve user applications until then.
7. Verify a wrong PIN does not start Tessera, the chosen PIN starts the session,
   and session exit returns to the phone greeter. Inspect logs without recording
   secrets. Verify the recovery path before declaring boot-time login complete.

Rollback: disable greetd, restore the saved tty1 configuration, then re-enable
that previous login path. Rollback does not silently restore the old password.
Do not claim secure locking: this feature authenticates a new session and does
not protect an already-running session with a Wayland session lock.

## References

- [Quickshell 0.3.1 Greetd API](https://quickshell.org/docs/v0.3.1/types/Quickshell.Services.Greetd/Greetd/)
- [greetd configuration](https://man.archlinux.org/man/greetd.5.en)
- [greetd IPC protocol](https://man.archlinux.org/man/greetd-ipc.7.en)
