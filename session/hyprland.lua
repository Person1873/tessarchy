-- Tessarchy defaults: Hyprland 0.56.x Lua API.
-- This is loaded explicitly, never over the user's Hyprland config.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.config({
    general = { gaps_in = 0, gaps_out = 0, border_size = 0, layout = "dwindle" },
    decoration = { rounding = 18, blur = { enabled = false }, shadow = { enabled = false } },
    animations = { enabled = false },
    input = { kb_layout = "us", follow_mouse = 0 },
    misc = { disable_hyprland_logo = true, force_default_wallpaper = 0 },
})
-- Initial mobile policy: new non-floating apps maximize between the status and
-- navigation bars. Restoring returns to ordinary dwindle tiling. Dialogs retain
-- compositor defaults; continuous single-app enforcement is not implemented.
hl.window_rule({ name = "tessarchy-initial-maximize", match = { float = false }, maximize = true })
hl.on("hyprland.start", function ()
    hl.exec_cmd("tessera-shell")
end)
hl.bind("SUPER + Return", hl.dsp.exec_cmd("foot"))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("tessera-shell"))
hl.bind("SUPER + SHIFT + E", hl.dsp.exit())
-- Preferences are user-owned, never installed over existing files.
local home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local preferences = home .. "/tessarchy/preferences.lua"
local f = io.open(preferences, "r")
if f then f:close(); dofile(preferences) end
