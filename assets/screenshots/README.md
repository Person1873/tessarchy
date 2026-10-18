# Quiet Edge development captures

Actual QEMU/KVM development-VM screenshots. The 2026-10-18 VM/touch checkpoint
uses the owner-accepted software display profile, with KVM CPU acceleration,
two audio outputs and virtio multitouch. The current captures use guest grim.
Dimensions, exact source commit and SHA-256 hashes are in capture-manifest.json.

Current captures:

- Phone home, launcher, switcher, settings, contacts, dialer, messages, sounds,
  cellular settings, Bluetooth and pull-down controls: 400x800.
- Tablet home and controls: 800x1280, automatic Tablet selection.
- Desktop home, controls, audio outputs and two-column Messages: 1280x800,
  automatic Desktop selection.

The example contact is synthetic: Tessarchy Demo, reserved 202-555-0123 number,
with the official logo as its imported photo. The switcher contains a real Foot
window with a synthetic touch-test note. No real calls or SMS were sent. Audio
controls show actual detected outputs; cellular, radio and battery controls show
the guest's unavailable hardware. The Messages composer is empty.

The three PIN-login captures retain their earlier greetd/PAM validation context:
entry, rejection and authenticated home. Earlier preview-labelled login PNGs are
separate assets and are not included in the website's screenshot ZIP.

The website ZIP contains twenty captures. These development captures are separate
from the published Alpha 2 ISO and its boot evidence.
