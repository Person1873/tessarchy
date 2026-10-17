# Architecture and API evidence

Tessarchy is an Arch session, not Android/AOSP. Tessera runs as a normal user
under Hyprland, using Quickshell's layer-shell panels and window integration.
No privileged daemon or compositor fork is involved.

A per-output status bar reserves 48 logical pixels. Navigation reserves 72 in
Phone mode and 80 in Tablet/Desktop. Phone navigation spans the output;
Tablet/Desktop use centered, rounded panels bounded to 720/760 pixels. Launcher
columns and panel height follow available space, including manual modes on small
screens. Settings is loaded only when opened. Panels never acquire application
keyboard focus; buttons and sliders use NoFocus. No keyboard search or outside
click dismissal is implemented.

`LayoutPolicy.js` classifies logical screen geometry: a shortest edge below 600
is Phone; otherwise a landscape width >=1100 and height >=650 is Desktop;
remaining sizes are Tablet. This is a display-size heuristic, not physical device
or input-hardware identification. Automatic mode is evaluated per output whenever
geometry changes; an explicit override applies across outputs. The override and
appearance preferences persist through QtCore Settings in
`$XDG_CONFIG_HOME/tessarchy/shell.ini` (default `~/.config/tessarchy/shell.ini`).
Dev uninstall preserves this user-owned file.

Hyprland.toplevels supplies window identity/title/state; each `.wayland` handle
provides activate(), close() and writable maximized. Close confirmation retains
the selected object rather than whichever window later becomes active. Closed
handles clear the confirmation. Windows lacking a handle have disabled actions.
These requests can be ignored by a compositor/application and need manual tests.
Only fixed `hl.dsp.exit()` goes through Hyprland.dispatch. No application title
is interpolated into IPC or a shell command. App launch uses
Quickshell.execDetached([executable]) per action, so no shared Process can drop
rapid clicks. Startup executables in the Lua config are fixed strings.

The Lua `window.open` handler reads the saved mode for each new ordinary window.
It uses the same size thresholds, accounting for monitor scale/rotation. Mobile
modes request maximization; Desktop leaves ordinary dwindle tiling. Floating
windows and windows already fullscreen are left alone. A mode switch does not
rearrange existing windows. Tablet split layouts and continuous mobile window
policy remain future work. Multi-output navigation lists global windows;
per-output geometry is used for automatic mode and each new window's monitor.

The original T logo is built from six SVG faces. BrandMark animates assembly and
rotation once, settles after 1.6 seconds, and supports tap/replay and reduced
motion. It has no idle animation loop. The clock updates once per minute; mode
selection is reactive, with no polling. Optional PipeWire integration is loaded
only when the service socket exists at launch. No hardware Wi-Fi/modem control
or secure locking is claimed.

## Verified against installed files, 2026-10-16

- Hyprland 0.56.2: `/usr/share/hypr/hyprland.lua`,
  `/usr/share/hypr/stubs/hl.meta.lua`, and `Hyprland --verify-config`.
- Quickshell 0.3.1: installed QML metadata under `/usr/lib/qt6/qml/Quickshell/`,
  especially Hyprland/_Ipc, Wayland/_ToplevelManagement and _WlrLayerShell;
  `qs --help` confirms path selection and duplicate protection.
- [Quickshell Toplevel API](https://quickshell.org/docs/types/Quickshell.Wayland/Toplevel/)
  documents activation, close and maximize as compositor requests.
- [Hyprland window rules](https://wiki.hypr.land/configuring/core/rules/window-rules/)
  documents the Lua maximize rule.
- [Official archiso profile specification](https://github.com/archlinux/archiso/blob/master/docs/README.profile.rst)
  and [releng profile](https://github.com/archlinux/archiso/blob/master/configs/releng/profiledef.sh)
  inform the overlay; installed archiso supplies the actual bootloader files.

No overlays claim secure locking. No lock button is included.

## On-screen keyboard

The session starts `tessarchy-osk start` after Tessera. When squeekboard is
installed it runs as an ordinary client and reserves its own `osk` layer above
the navigation bar, so maximized apps shrink rather than being covered.
squeekboard shows itself for focused text fields only when the GNOME a11y key
`screen-keyboard-enabled` is true. Rather than change that global user setting,
the wrapper starts it with a keyfile GSettings backend under
`$XDG_STATE_HOME/tessarchy/osk` (default `~/.local/state/tessarchy/osk`), seeded
once with the key enabled. Users may edit that file; it is never overwritten.
The Keyboard navigation button calls `tessarchy-osk toggle`, which uses
squeekboard's `sm.puri.OSK0` D-Bus `Visible`/`SetVisible` on the session bus. Tessera
panels never take keyboard focus, so the app keeps its text field. The button
appears only when `tessera-shell` finds squeekboard and the wrapper, and is not
added to Desktop mode. Without squeekboard nothing starts and no button appears.
The guest test observed squeekboard load its terminal layout for Foot and its
text layout for Firefox's address bar, so text-input content purpose reached it;
the exact protocol traffic was not traced.

## System theme

Omarchy's model: the theme's `colors.toml` is the source, and each consumer gets
a rendered file. `tessarchy-theme` searches `~/.config/tessarchy/themes`, the
installed `themes/`, then `/usr/share/omarchy/themes`, and stages the choice in
`$XDG_STATE_HOME/tessarchy/theme/`:

- `colors.toml` (normalised palette) feeds the shell's `Theme` singleton through
  a watched `FileView`, so the shell changes live. Icons are white SVGs tinted by
  `Icon`.
- `foot.ini` includes the user's own foot config, then sets the palette.
  `tessarchy-run foot` uses it; already-open themed terminals are recoloured with
  OSC 4/10/11/12.
- `osk/gtk-3.0/gtk.css` sits in squeekboard's private config home. Its user CSS
  provider (priority 800) overrides squeekboard's own (600). `tessarchy-osk
  restart` reloads it.
- `mode` (dark/light, or derived from background luminance) sets `GTK_THEME` /
  `ADW_DEBUG_COLOR_SCHEME` for apps started through `tessarchy-run`. GTK apps get
  only Adwaita dark/light, not the palette.
- `wallpaper` names the theme's first background, which replaces the Tessera
  artwork on the home screen.
