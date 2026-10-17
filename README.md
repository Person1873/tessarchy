# Tessarchy

Arch Linux + Hyprland + **Tessera**, a touch-first Quickshell session for small
screens. This repository contains real prototype source and an experimental
archiso staging pipeline. **No boot-tested Tessarchy ISO has been produced yet.** Two local development
packages have been built in `dist/`; their installation and UI still need testing.

Implemented: 56px touch buttons, persistent 72px bottom dock, Firefox/Foot
launcher, scrollable window overview, maximize/restore, confirmed close and
confirmed session exit. Native Quickshell handles target the selected window;
launches use independent argument-vector executions. No universal Back button.

New non-floating windows initially maximize above the dock. Restore returns to
normal tiling; there is no continuous mobile window policy. Floating dialogs,
multiple maximized windows, and application sizing require VM/device validation.
Exclusive fullscreen can cover the dock. This is not a secure lock screen.
**Text input currently requires a physical keyboard.**

## Quick start: use the basic Arch VM

The basic Arch qcow2 is now the preferred development route. The user has
confirmed that the basic Arch image boots and Tessera runs in that guest.
Detailed touch/device acceptance testing and ISO boot testing remain pending.

Shut down the current guest with `sudo poweroff`. From the host repository:

```bash
./scripts/run-basic-vm.sh
```

This uses `vm/Arch-Linux-x86_64-basic.qcow2`, preserves the separate blank disk,
and exports a fresh read-only snapshot of the project on each launch. Stop the
previous VM before launching the same disk again. KVM is used when accessible;
TCG is the slow fallback. Defaults are 2GiB RAM and 2 vCPUs.

Log into the guest as `arch` (initial password `arch`). **Inside the guest**:

```bash
sudo pacman -Syu --needed hyprland quickshell firefox foot mesa qt6-declarative qt6-wayland ttf-dejavu python
sudo poweroff
```

Restart on the host with `./scripts/run-basic-vm.sh` (or
`VM_SSH_PORT=2222 ./scripts/run-basic-vm.sh` when using SSH), then log back in.
This ensures updated kernel modules match the running guest kernel. Continue
inside the guest:

```bash
sudo modprobe 9pnet_virtio
sudo modprobe 9p
sudo mkdir -p /mnt/tessarchy
sudo mount -t 9p -o trans=virtio,version=9p2000.L,ro tessarchy /mnt/tessarchy
cp -r /mnt/tessarchy/tessarchy ~/
cd ~/tessarchy
./scripts/setup-guest.sh --autostart
~/.local/bin/start-tessarchy
```

The pacman command explicitly updates the **guest** and installs dependencies.
Do not run it on the host for this workflow. The copy command assumes a new
`~/tessarchy` guest directory; preserve any existing guest work first. Setup
refuses Omarchy/the host, checks dependencies and syntax, then installs a
namespaced user copy. Nothing is installed automatically on the host.

With `--autostart`, Tessarchy starts after normal login on tty1 (no autologin).
Existing `.bash_profile` content is retained and backed up; ending Tessarchy
returns to the prompt. Omit the flag for manual startup. To undo the login hook:

```bash
./scripts/login-session.sh disable
```

The hook does not affect other TTYs. Initial text input needs a physical keyboard.
The virtual USB tablet is an absolute mouse, not a multitouch touchscreen.
See [VM setup](docs/vm.md) for recovery and the alternative stock-ISO route.

## Development install in an Arch guest

Dependencies are **a separate explicit opt-in step**, never installed by scripts:

```bash
sudo pacman -S --needed hyprland quickshell firefox foot mesa qt6-declarative qt6-wayland ttf-dejavu
./scripts/check.sh
./scripts/install-dev.sh
```

Assumptions: x86_64 Arch, Hyprland **0.56.x** Lua API and Quickshell **0.3.1**.
Newer versions require revalidation. Bash, Python 3, coreutils, D-Bus and Qt 6
are required. Optional integration: xdg-desktop-portal-hyprland,
xdg-desktop-portal-gtk, PipeWire, WirePlumber and XWayland. Dependencies must
match a consistent Arch system; scripts never upgrade the host.

Log out of other graphical sessions, switch to a **local TTY**, log in as the
development user, then:

```bash
~/.local/bin/start-tessarchy
```

Defaults are copied under `$XDG_DATA_HOME/tessarchy` (normally
`~/.local/share/tessarchy`); launchers go in `~/.local/bin`. Existing paths are
refused. Existing Hyprland/Quickshell/Omarchy configs are untouched. User
preferences live separately in `~/.config/tessarchy/preferences.lua`; see
`session/preferences.example.lua`. Dev installation does not register with a
display manager. Reloaded defaults require uninstall/reinstall; preserve any
custom source changes in the repository.

```bash
./scripts/login-session.sh disable  # if enabled
./scripts/uninstall-dev.sh
```

Uninstall preserves preferences and unknown extra files, and refuses to delete
modified launchers. Keep the source version used to install for uninstalling.

## Start the ISO work

On a normal Arch terminal with administrator access and internet:

```bash
sudo pacman -S --needed archiso
./scripts/stage-iso.sh
./scripts/build-iso.sh
./scripts/vm.sh run dist/tessarchy-0.1.0-YYYYMMDD-x86_64.iso
```

Use the actual ISO filename in `dist/`. Staging is unprivileged; building uses
sudo for `mkarchiso`, downloads signed repository packages, and creates mounts
in its work directory. Read [ISO design](docs/iso.md) before building. This
is a live development image, not an installer or supported distribution.

## Packaging and layout

`./scripts/package.sh` builds two local packages using makepkg without installing
them or resolving missing dependencies. These copy-only recipes use makepkg
`--nodeps` so both can be built before either is installed; dependency checks
still happen when pacman installs them. Build prerequisites: `base-devel` and
`pacman-contrib` if needed by your Arch tooling. Then explicitly install **both**
packages with `sudo pacman -U dist/tessera-shell-*.pkg.tar.zst dist/tessarchy-session-*.pkg.tar.zst`.
Remove with `sudo pacman -R tessarchy-session tessera-shell`. Remove a dev copy
first to avoid taking precedence over system packages. Local source archives
use `SKIP` checksums; release packaging and version pinning are future work.

- `shell/`: Tessera QML; `session/`: launcher, Lua config and desktop entry.
- `scripts/`: local install, checks, packaging, VM and ISO tools.
- `packaging/`: Arch recipes; `iso/`: package additions and live overlay.
- `tests/`: safety/integration checks; `assets/`: asset provenance.
- `docs/`: architecture, VM, ISO, roadmap and manual test checklist.

See [testing status](docs/testing.md) for what was actually checked.
