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
-- Read the same saved mode as Tessera when a new ordinary app opens.
-- Existing windows and floating dialogs are left alone when modes change.
local function shell_mode(monitor)
    local config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
    local file = io.open(config .. "/tessarchy/shell.ini", "r")
    local mode, section = "auto", ""
    if file then
        for line in file:lines() do
            section = line:match("^%[([^%]]+)%]%s*$") or section
            if section == "Shell" then
                mode = line:match("^%s*layoutMode%s*=%s*(%a+)%s*$") or mode
            end
        end
        file:close()
    end
    if mode == "phone" or mode == "tablet" or mode == "desktop" then return mode end
    local width, height = monitor.width / monitor.scale, monitor.height / monitor.scale
    if monitor.transform % 2 == 1 then width, height = height, width end
    if math.min(width, height) < 600 then return "phone" end
    if width >= 1100 and height >= 650 then return "desktop" end
    return "tablet"
end
-- Phone/Tablet keep one primary app: an ordinary window is maximized when it
-- opens and again whenever it becomes active (switching apps, or the app below
-- surfacing after a close). Restore holds until focus moves elsewhere.
local function maximize_if_mobile(window)
    if not window or window.floating or window.fullscreen ~= 0 or not window.monitor then return end
    if shell_mode(window.monitor) ~= "desktop" then
        hl.dispatch(hl.dsp.window.fullscreen({ window = window, mode = "maximized", action = "set" }))
    end
end
-- Dialogs stay floating above their app, but on Phone/Tablet one larger than
-- the space between the bars (and keyboard) is shrunk to fit and centered, so
-- buttons such as Cancel/Save are reachable. Apps may refuse sizes below their
-- minimum; Hyprland then keeps the smallest size the app accepts.
local function fit_dialog(window)
    if not window or not window.floating or not window.monitor then return end
    local size = window.size
    if type(size) ~= "table" or not size.x or not size.y then return end
    local monitor = window.monitor
    if shell_mode(monitor) == "desktop" then return end
    local width, height = monitor.width / monitor.scale, monitor.height / monitor.scale
    if monitor.transform % 2 == 1 then width, height = height, width end
    local reserved = type(monitor.reserved) == "table" and monitor.reserved or {}
    width = math.floor(width - (reserved.left or 0) - (reserved.right or 0))
    height = math.floor(height - (reserved.top or 0) - (reserved.bottom or 0))
    if size.x <= width and size.y <= height then return end
    hl.dispatch(hl.dsp.window.resize({ window = window, x = math.min(size.x, width), y = math.min(size.y, height) }))
    hl.dispatch(hl.dsp.window.center({ window = window }))
end
hl.on("window.open", function(window)
    maximize_if_mobile(window)
    fit_dialog(window)
end)
hl.on("window.active", maximize_if_mobile)
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
