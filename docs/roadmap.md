# Roadmap

See [Operation Tessarchy](../Operation-TESSARCHY.md) for the design brief.

## Implemented in the development branch

- Quiet Edge: shallow frosted status bar, floating glass navigation, minimal icons.
- Swipeable app cards, live previews when available, icon actions, confirmed close.
- Automatic Phone/Tablet/Desktop layouts with saved overrides and appearance settings.
- Original wallpaper, finite cube logo animation, reduced motion.
- Experimental x86_64 Alpha 1 live ISO, observed BIOS/UEFI QEMU/KVM GUI boots.
- GitHub Pages project site, real screenshot pack, automatic repository deployments.

The published Alpha 1 ISO predates Quiet Edge and the card switcher. New UI work
is tested in the installed development VM until another ISO is built and booted.

## Next implementation steps

1. Refine card transitions and physical touchscreen interactions; add configurable
   gestures while retaining visible navigation and >=48px touch targets.
2. Validate on-screen keyboard protocols, focus and resize with Foot and Firefox.
3. Propose a narrow-screen default app set for approval before integration.
4. Extend tablet split layouts, continuous mobile window policy and rotation.

## Investigation, not device support

- Verify exact OnePlus 7/8 models; consider 6/6T if compatibility is better.
- Document boot, display, touch, graphics, Wi-Fi, charging, suspend, audio and
  cellular status before recommending hardware or flashing anything.
- Research existing dialers/messaging and modem integration separately.
- Scope a WebUSB installer to one verified device with recovery instructions and
  explicit confirmation before destructive operations.
- Verify OpenRouter integration, pricing, privacy and budget limits before paid use.

No universal ARM image, cellular/SMS support, secure lock, production update
system, or phone flasher is currently claimed.
