# Arch development VM

## Preferred: existing Basic image → Tessarchy

The user has booted the official Basic qcow2. Shut it down (`sudo poweroff` in
the guest), then run `./scripts/run-basic-vm.sh` on the host. This boots that
same disk, not the earlier empty `tessarchy.qcow2`, and creates a fresh read-only
9p source snapshot for the VM's lifetime. It never changes a running disk through
offline tools. QEMU's normal disk locking prevents concurrent writers; close the
previous instance first. No SSH forwarding or host service is needed.

Follow the guest commands in [README](../README.md#quick-start-use-the-basic-arch-vm).
`setup-guest.sh` runs only as a non-root user in an Arch QEMU/KVM VM. It checks
that required executables exist, runs available validation, and installs the
dev copy; it does not call pacman or sudo. The optional `--autostart` enables
Tessarchy after tty1 login using a managed block in `.bash_profile`. It backs
up existing content and refuses modified blocks or symlinked profiles. Disable
with `./scripts/login-session.sh disable` before uninstalling the session.

If startup fails, the hook returns to a shell rather than restarting in a loop.
Use another TTY to disable it if needed. Default Basic image credentials are for
initial setup; change the guest password with `passwd`. The image includes SSH,
but this launcher exposes no forwarded ports. This workflow makes a prototype
session; it does not turn the guest into a production distribution or ISO.

## Alternative: install Arch from the full ISO

Run scripts from the repository root. `vm.sh init` creates an empty sparse 32GiB
qcow2 and preserves any existing disk. It does not install an OS. Download the
stock Arch ISO with `fetch-arch-iso.sh`, then pass the printed path to `vm.sh run`.
The downloader needs curl, gpgv and the Arch keyring. Verification errors stop it;
refresh your keyring explicitly if needed rather than bypassing signature checks.

The default 2GiB RAM suits a small host; Firefox plus an ISO build will need more.
For a larger machine use `VM_RAM=4096 VM_CPUS=4 ./scripts/vm.sh run <ISO>`.
`VM_ACCEL=tcg` forces software emulation. `VM_UEFI=1` opts into OVMF firmware and
a persistent guest variables file. `vm.sh plan <ISO>` prints the command without
starting QEMU. `VM_DISPLAY=sdl` selects another graphical backend.

No `/dev/kvm` was exposed to the coding session. Check on your actual host:

```bash
ls -l /dev/kvm
```

KVM needs CPU virtualization and device permissions; nested virtualization may
need enabling on the outer host. The scripts do not change host groups, kernel
modules or firmware settings. TCG can boot without those, but is much slower.
The default virtio-vga display has GL off for broad host compatibility. Hyprland
may require software Mesa rendering in the guest: from a guest TTY try
`LIBGL_ALWAYS_SOFTWARE=1 ~/.local/bin/start-tessarchy`. This fallback is untested.
Accelerated virtio-gpu/virgl graphics is a later validation task.

## Install and enter Arch

1. Boot the verified official Arch ISO. Use `archinstall` interactively for a
   minimal installation. The guest disk is `/dev/vda`, 32GiB. Select **only the
   guest virtual disk** and create a normal user with sudo access. Do not run
   installer commands on the host. No unattended disk formatting is provided.
2. Shut down the guest, then `./scripts/vm.sh run` without an ISO to boot the
   installed system. Log in as the normal user.
3. To transfer the project, prepare a fresh read-only snapshot on the host:
   `./scripts/export-vm-source.sh`. Start QEMU with
   `VM_SHARE=1 ./scripts/vm.sh run` (append an ISO only for installer boot).
4. Inside the guest:

```bash
sudo mkdir -p /mnt/tessarchy
sudo mount -t 9p -o trans=virtio,version=9p2000.L,ro tessarchy /mnt/tessarchy
cp -r /mnt/tessarchy/tessarchy ~/tessarchy
cd ~/tessarchy
sudo pacman -S --needed hyprland quickshell firefox foot mesa qt6-declarative qt6-wayland ttf-dejavu
./scripts/check.sh
./scripts/install-dev.sh
~/.local/bin/start-tessarchy
```

The snapshot never includes the VM disk, host configuration, or `.git`. It is
read-only in the guest, but not a security boundary for untrusted guests. Stop
the VM and remove `build/vm-share` to refresh it; then export again. Changes made
in the guest copy do not propagate back automatically.

## Exit and recovery

Tap Session → End session (confirmation). The prototype returns to the local
TTY. Keyboard recovery: Super+Return launches Foot, Super+F toggles maximize,
Super+Shift+F toggles exclusive fullscreen, Super+Shift+R restarts Tessera if it
has exited, and Super+Shift+E exits Hyprland immediately (unsaved work at risk).
Ctrl+Alt+F2 switches to another guest TTY when delivered by the host/QEMU.
Use QEMU's Send Key menu if the host captures a chord. Closing the QEMU window
is equivalent to abrupt power loss; shut the guest down normally when possible.

The emulated USB tablet supplies an absolute mouse pointer, not touchscreen
multitouch. Use mouse clicks for the first UI pass; actual touch needs a device
or deliberate input passthrough later. Portrait/scaled layouts can be requested
with a guest `~/.config/tessarchy/preferences.lua`, for example:

```lua
hl.monitor({ output = "", mode = "720x1280@60", position = "auto", scale = 2 })
```

Virtual hardware may reject this mode. Inspect `hyprctl monitors`, use supported
modes, or test with a nested compositor/headless output on a suitable machine.
Do not claim portrait/touch coverage from the default landscape VM alone.

## Slow ISO downloads

The downloader uses one HTTP connection to geo.mirror.pkgbuild.com by default.
A slow route or mirror can limit it; the script applies no bandwidth cap. To try
the official Fastly mirror, cancel the current download and run:

```bash
ARCH_ISO_MIRROR=https://fastly.mirror.pkgbuild.com/iso/latest ./scripts/fetch-arch-iso.sh
```

Cancellation currently discards the temporary partial download, so this starts
again. Checksums and signature verification still run. A different mirror is
not guaranteed to be faster. Arch also offers torrents and a tiny netboot loader;
netboot still downloads the live system at boot and is not a tiny offline Arch.

## Clipboard-friendly setup via SSH

The initial QEMU text console has no normal clipboard integration. Type
`sudo poweroff` in the guest, then restart from the host with:

```bash
VM_SSH_PORT=2222 ./scripts/run-basic-vm.sh
```

Keep QEMU running. In another host terminal:

```bash
ssh -p 2222 arch@127.0.0.1
```

Use the guest password (initially `arch`). You can paste dependency installation,
9p mount and setup commands into this SSH terminal using Ctrl+Shift+V. Start
`~/.local/bin/start-tessarchy` in the VM's local console, not over SSH. This
explicit opt-in forwarding binds only to host loopback; no forwarding exists
when VM_SSH_PORT is unset. If SSH is refused after the guest has finished
booting, type `sudo systemctl start sshd` in the guest console and retry.

The option follows the [official QEMU user-network forwarding syntax](https://www.qemu.org/docs/master/system/invocation.html).

## Unknown filesystem type 9p

If `mount -t 9p` fails, load `9pnet_virtio` and `9p` with modprobe in the guest.
If modprobe reports that the module is missing from the running kernel's module
directory after a package update, shut down the guest and relaunch the VM. The
newly installed kernel/modules only match after restarting. This launcher uses
`-no-reboot`, so a guest reboot also exits QEMU; `sudo poweroff` followed by the
host launcher is the clearest path. Keep `VM_SSH_PORT=2222` when relaunching if
using SSH. Retry the mount after logging back in. If it still fails, capture the
full mount/modprobe output and `uname -r` rather than installing random packages.
