# Roadmap

1. **Prototype, implemented with user-reported VM smoke test:** Tessera navigation,
   apps, windows, maximize/restore, confirmed close/exit, namespaced user install,
   package recipes and VM workflow. Validate on the installed API versions.
2. **Live image, started:** assemble a releng overlay; build and boot it, fix
   boot/user/graphics failures, test BIOS/UEFI, then package payloads properly.
3. **Text input, started:** squeekboard is integrated as an optional keyboard and
   validated under Tessarchy's Hyprland in QEMU with Foot and Firefox, synthetic
   touch, focus retention and app resizing. Remaining: real touch hardware, GTK
   and Qt apps, rotation/scale, layout/theme matching Tessera, and Desktop mode.
4. **Mobile policy:** continuous primary-window behavior, transient dialogs,
   rotation, scale presets and actual touchscreen tests. Current rule only
   maximizes on map; restore falls back to tiling.
5. **Tablet/docked:** optional two-app split and conventional tiling profiles.
6. **Hardware:** explicit x86_64 tablets first; selected ARM devices only with
   documented boot, graphics and input support.

Not in milestone 1: cellular/SMS, Android/Waydroid, secure lock screen, custom
kernel, arbitrary Android phone ports, universal ARM images or production updates.
