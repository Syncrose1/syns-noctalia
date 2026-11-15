-- Entry point: CachyOS's stock config (config/, refreshed from /etc/skel by
-- ~/.local/bin/sync-cachyos-config) with my own layer on top (user/).
-- Edit files in user/, not config/.

local function read_hostname()
    local f = io.open("/etc/hostname", "r")
    local name = f and f:read("*l") or ""
    if f then f:close() end
    return name
end

-- This machine's monitors and workspaces: user/hosts/<hostname>.lua (optional)
local host = {}
local host_file = os.getenv("HOME") .. "/.config/hypr/user/hosts/" .. read_hostname() .. ".lua"
local f = io.open(host_file, "r")
if f then
    f:close()
    host = dofile(host_file)
end

-- CachyOS Hyprland Configuration (same order as /etc/skel/.config/hypr/hyprland.lua)
require("config.animations")
require("config.autostart")
require("config.colors")
require("config.decorations")
require("config.variables")
require("user.vars")
if host.vars then host.vars() end
require("config.environment")
require("config.inputs")
require("config.binds")
require("config.misc")
require("config.monitors")
require("config.windowrules")
require("config.workspaces")

-- My layer
require("user.shared")
if host.setup then host.setup() end

-- For Noctalia Color templates
require("noctalia").apply_theme()
