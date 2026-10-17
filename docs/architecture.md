# Architecture and API evidence

Tessarchy is an Arch session, not Android/AOSP. Tessera runs as a normal user
under Hyprland, using Quickshell's layer-shell panels and window integration.
No privileged daemon or compositor fork is involved.

A per-output PanelWindow reserves 72 logical pixels. It expands upward for the
launcher, overview and confirmations without reserving the whole drawer area.
Its top layer keeps navigation over maximized apps; keyboardFocus=None prevents
navigation from acquiring application keyboard focus. Buttons use NoFocus.
The drawer intercepts touches inside its bounds only; applications remain
interactive elsewhere. There is no outside-click dismissal or keyboard search.

Hyprland.toplevels supplies window identity/title/state; each `.wayland` handle
provides activate(), close() and writable maximized. Close confirmation retains
the selected object rather than whichever window later becomes active. Closed
handles clear the confirmation. Windows lacking a handle have disabled actions.
These requests can be ignored by a compositor/application and need manual tests.
Only fixed `hl.dsp.exit()` goes through Hyprland.dispatch. No application title
is interpolated into IPC or a shell command. App launch uses
Quickshell.execDetached([executable]) per action, so no shared Process can drop
rapid clicks. Startup executables in the Lua config are fixed strings.

The initial static rule maximizes new non-floating apps. It does not enforce a
single-primary-app policy when focus changes, handle complex transient windows,
or implement tablet splitting. Normal tiling can reappear after restoring.
Multi-output panels show the same global window list. Focus/session exit affect
the whole compositor. Minimum supported layout is 320×480 logical pixels;
font/scaling and windows with large minimum sizes need real-device testing.

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

No overlays claim secure locking. No lock button is included. A complete input
method integration needs research into Hyprland's input-method-v2/text-input-v3,
client toolkit support, focus behavior and whether the chosen keyboard actually
implements the required protocols. Squeekboard/Maliit are not assumed compatible.
