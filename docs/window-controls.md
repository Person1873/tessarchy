# Desktop window controls

Tessarchy's optional Hyprbars integration supplies a draggable title bar with
Minimize, Maximize/Restore and confirmed Close. Buttons occupy 48px squares.
The desktop opening geometry includes the title bar in the available space.

Minimize moves a window to a private special workspace. Its workspace name
encodes the original workspace and fullscreen state, so a configuration reload
does not lose the return location. Other windows remain independent. Taskbar,
Alt+Tab and touch Recents activation restore the selected window before focusing
it. Closing an application removes its minimized state with its workspace.

## Optional plugin build

The session runs without the plugin. To enable title bars, build the official
Hyprland plugin pin for the exact installed compositor version. The provided
script targets Hyprland 0.56.2, commit
`efb50993780079460b0cbed1363e2166a2de1d9f`, and upstream plugin commit
`7644cecdb947060682891a0db2a0cdc5c0b9e704`.

With matching Hyprland headers, compiler, Make and pkg-config dependencies
already installed:

```sh
./scripts/build-window-bars.sh
```

The output is `dist/hyprbars-0.56.2.so`. In a Tessarchy development installation,
place it at `$XDG_DATA_HOME/tessarchy/plugins/hyprbars.so`, or
`$HOME/.local/share/tessarchy/plugins/hyprbars.so` when XDG_DATA_HOME is unset,
then reload the Tessarchy session configuration. A packaged installation reads
`/usr/share/tessarchy/plugins/hyprbars.so`. Never overwrite a loaded library;
unload it before replacing it. The session loads the optional file and applies
its button configuration. The binary is not committed or included in the ISO.

The script applies `patches/hyprbars-touch.patch`: touch hit testing uses the
contact position and accepts nonzero contact IDs, preventing the mouse position
or another overlapping window from deciding which title bar receives a tap.
No build dependencies are installed by the script. A compositor upgrade requires
a new matching plugin build. Actual VM acceptance is recorded in
[testing.md](testing.md).
