# Roadmap

1. **Prototype, implemented with user-reported VM smoke test:** Tessera navigation,
   apps, windows, maximize/restore, confirmed close/exit, namespaced user install,
   package recipes and VM workflow. Validate on the installed API versions.
2. **Live image, started:** assemble a releng overlay; build and boot it, fix
   boot/user/graphics failures, test BIOS/UEFI, then package payloads properly.
3. **Text input:** research compositor and input-method protocols; validate an
   on-screen keyboard with Foot and Firefox, touch focus and resize behavior.
   A physical keyboard is required until this is done. No keyboard is recommended
   purely because it works under another compositor.
4. **Mobile policy, started:** apps re-maximize on activation and oversized
   dialogs fit the usable area (QEMU-tested with Foot and Firefox's GTK file
   chooser). Remaining: dialogs that resize after mapping, rotation and scale
   presets on real outputs, and actual touchscreen tests.
5. **Tablet/docked:** optional two-app split and conventional tiling profiles.
6. **Hardware:** explicit x86_64 tablets first; selected ARM devices only with
   documented boot, graphics and input support.

Not in milestone 1: cellular/SMS, Android/Waydroid, secure lock screen, custom
kernel, arbitrary Android phone ports, universal ARM images or production updates.
