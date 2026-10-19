# Installing from the live image

The ISO is a live system, not an installer-only disc. Boot it, use the shell on
the real hardware, and decide whether the machine is a good fit. The installer
then copies that exact running system onto an internal disk, so what you tested
is what you get — no second download, no different package set.

Nothing is written until the confirmation prompt is answered, and the live
medium itself is detected and refused as a target.

## 1. Try it

1. Write the ISO to a USB stick (`dd if=tessarchy-*.iso of=/dev/sdX bs=4M
   status=progress oflag=sync`).
2. Boot it. The session starts automatically on the local console.
3. Use it as a normal machine: open apps, check touch, sound, Wi-Fi, rotation.

## 2. Check the fit

```sh
sudo tessarchy-install --check
```

This reports the things that decide whether the machine will work: firmware
mode (UEFI or BIOS), the detected GPU, whether the live session is running on
Wayland, RAM, touch devices, and how many disks are available as targets.

It is a summary, not a benchmark. The live session you just used is the real
answer.

## 3. Pick a disk

```sh
sudo tessarchy-install --list
```

Whole disks only. Loops, `zram`, optical drives and the live medium are filtered
out and marked. Internal storage normally appears as `/dev/nvme0n1`,
`/dev/mmcblk0` or `/dev/sda`.

## 4. Install

```sh
sudo tessarchy-install --disk /dev/nvme0n1
```

The tool then:

1. Writes a fresh GPT layout — ESP plus root, adding a BIOS boot partition on
   legacy firmware.
2. Formats the ESP as FAT32 and the root as ext4 labelled `tessarchy`.
3. Copies the running live root with `rsync` (excluding `/proc`, `/sys`, `/dev`,
   `/run`, `/tmp` and the live mount).
4. Generates `fstab`, writes the hostname, drops the live image's archiso
   initramfs hook and rebuilds a normal initramfs.
5. Installs the bootloader: systemd-boot with a `Tessarchy` entry on UEFI,
   GRUB on legacy BIOS.
6. Enables NetworkManager, Bluetooth and the greeter.

The confirmation prompt repeats the target path; `--yes` skips it for scripted
installs.

## 5. Reboot

Remove the live medium, reboot, and the installed system starts the same shell.

## Limits worth knowing

- **The whole disk is erased.** There is no dual-boot mode and no partition
  picker yet.
- **The copy is offline.** Everything comes from the ISO; without working
  networking afterwards, no updates are applied.
- **`rsync -aHAX` is not a package transaction.** The installed system is a
  clone of the live image, so it inherits the image's snapshot even if it is
  months old. Run a full `pacman -Syu` on first boot.
- **Secure Boot is not configured.** Disable it, or enrol keys yourself.
- **Physical hardware acceptance is still pending** for the installed-disk path;
  see [iso.md](iso.md).
