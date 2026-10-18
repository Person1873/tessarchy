# Quiet Edge development captures

Actual QEMU/KVM development-VM screenshots. The current Phone/Messages checkpoint
was captured on 2026-10-18 UTC through QMP screendump. Capture dimensions, source
context and SHA-256 hashes are in capture-manifest.json.

Current captures:

- Phone home, dialer, contacts, messages, sounds, cellular settings and pull-down controls: 400x800.
- Tablet home and controls: 800x1280, automatic Tablet selection.
- Desktop home, controls and two-column Messages: 1280x800, automatic Desktop selection.

The example contact is synthetic: Tessarchy Demo, reserved 202-555-0123 number,
with the official logo as its imported photo. No real calls or SMS were sent.
Cellular/audio/battery controls show the actual unavailable VM services. The
messages composer is empty; no simulated received/sent messages are presented.

The launcher, switcher, appearance-settings, Bluetooth and three PIN-login images
retain their earlier validation checkpoints. The PIN captures show actual greetd/
PAM entry, rejection and authenticated home. Earlier preview-labelled login PNGs
are separate assets and are not included in the website's screenshot ZIP.

The website ZIP contains nineteen published captures. These development captures
are separate from the published Alpha 2 ISO and its boot evidence.
