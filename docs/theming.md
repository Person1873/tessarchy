# Tessera shell themes

The system theme uses an unmodified Omarchy `colors.toml` as its palette. To
customize the shell *look* as well as its palette, optionally place a separate
`[tessera]` table in `shell.toml` alongside `colors.toml`. We keep this file
separate so stock Omarchy themes work without alterations; the theme launcher
appends it to the **staged** palette, read atomically by the shell. Never edit
the staged file: `tessarchy-theme set NAME` regenerates it.

Example `~/.config/tessarchy/themes/my-theme/shell.toml`:

```toml
[tessera]
glass = "#501c2c43"
glass_border = "#504d687d"
start_header_top = "#8c294d9e"
```

Qt uses `#AARRGGBB`: the first byte is opacity (`00` transparent, `ff`
opaque). All keys are optional. Without `shell.toml`, `Theme.qml` derives every
semantic colour from the palette, including translucent glass in light mode.
Changing themes resets absent overrides; no old theme's tint leaks into the next.

| Tokens in `shell.toml` | Purpose |
|---|---|
| `glass`, `glass_border`, `glass_strong`, `switcher_glass`, `bar_tint` | Controls/inputs, panel border, expanded panel/drawer, switcher, taskbar/Start menu tint (`barOpacity` preference still controls bar/Start opacity) |
| `danger_surface` | Destructive button fill |
| `start_header_top`, `start_header_bottom`, `start_header_text` | Start menu gradient and heading |
| `tile_glass`, `tile_selected`, `tile_pressed`, `tile_border`, `tile_icon_glass`, `tile_icon_border`, `tile_text` | Start menu tiles and icon wells |
| `switcher_card`, `switcher_button`, `switcher_button_border` | Window previews/actions |
| `tray_glass`, `tray_border`, `task_idle`, `task_border`, `task_bevel`, `task_pressed_bevel` | XP-style taskbar tray/buttons |
| `start_button_text`, `start_button_border`, `start_button_selected_border` | Start button contrast and edge |
| `input_text`, `input_placeholder`, `input_selection`, `input_border` | Glass text fields |
| `panel_text`, `panel_muted_text` | Status/quick settings text |
| `item_text`, `detail_text`, `subtitle_text`, `hint_text`, `caption_text`, `error_text` | Mobile page text: list items, body/detail lines, secondary lines, help and empty states, message metadata, errors |
| `message_incoming` | Incoming SMS bubble (outgoing follows `accent`) |
| `notification_card`, `notification_card_pressed`, `urgent_text`, `urgent_border` | Notification cards and popups, urgent label and edge |
| `lock_scrim`, `lock_muted_text`, `pin_dot`, `pin_dot_border`, `pin_key`, `pin_key_pressed`, `pin_key_border` | Sign-in screen over its artwork |

Accent-dependent selected/pressed variants live in the Theme singleton and
follow the active `accent`. `themes/tessera/shell.toml` captures upstream's
existing blue/mint glass values; the unlayered light theme uses palette-derived
tints rather than retaining dark blue. Radius and spacing remain component
geometry, not colour tokens; decide whether they should become theme parameters
before exposing them in configuration.

Shell QML holds no colour literals outside `Theme.qml`;
`test_shell_colors_live_in_theme_tokens` enforces this and requires every token to
be loadable and pinned in `themes/tessera/shell.toml`. The greeter runs as the
`greeter` account before any user theme is readable, so it loads the bundled
Tessera theme; `login-preview.qml` previews the sign-in screen under the active
staged theme.
