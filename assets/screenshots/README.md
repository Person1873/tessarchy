# Quiet Edge development captures

Fresh 2026-10-19 screenshots from actual QEMU/KVM guests. The development guest
uses software display rendering, KVM CPU acceleration, two audio outputs and
virtio multitouch. Captures use guest grim; the live-image capture uses QMP.
Dimensions, source commits and SHA-256 hashes are in capture-manifest.json.

- Phone home, launcher, stacked Recents, settings, contacts, dialer, messages,
  sounds, cellular settings, Bluetooth and controls: 390x844, automatic Phone.
- Real greetd/PAM entry, wrong-PIN rejection and authenticated home: 390x844.
- Tablet home and controls: 800x1280, automatic Tablet.
- Desktop home, controls, audio outputs and Messages: 1280x800, automatic Desktop.

The contact is synthetic: Tessarchy Demo, reserved 202-555-0123, with the official
logo as its photo. Recents shows real Calculator, Files and Foot windows with
synthetic terminal text. No calls or SMS were sent. Audio controls show detected
USB and HDA outputs; absent radio, modem and battery hardware remains visible.
The Messages composer is empty. Recents apps close immediately by upward swipe,
mouse double-click or the close button.

The screenshot ZIP contains twenty-one fresh captures. `live-launcher.png`
comes from a diskless UEFI boot of the Alpha 15 mirror development ISO, source
1a46da4. It is separate from the published Alpha 4 tester download and the newer
phone-session source. Earlier preview-labelled login PNGs are historical assets
outside the website screenshot ZIP. No images are visual mockups.
