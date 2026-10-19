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

Accent-dependent selected/pressed variants live in the Theme singleton and
follow the active `accent`. `themes/tessera/shell.toml` captures upstream's
existing blue/mint glass values; the unlayered light theme uses palette-derived
tints rather than retaining dark blue. Radius and spacing remain component
geometry, not colour tokens; decide whether they should become theme parameters
before exposing them in configuration.

Migration debt: 85 literal-colour lines remain in mobile login, communications,
settings subpages, notifications and greeter. `test_shell_colors_live_in_theme_tokens`
forbids new literals elsewhere and caps each temporary exception. Move these to
Theme tokens and lower the caps as each area is migrated.
