-- Shared tweaks for every machine, loaded after all of CachyOS's config/ files.
-- Later settings win in Hyprland, so everything here overrides the stock config.

local HOME = os.getenv("HOME")
local function exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

-- Environment: same as ~/.config/uwsm/env, so theming works in the plain "Hyprland" session too
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "kde")  -- KDE apps (Dolphin) read Noctalia's kcolorscheme this way
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("BROWSER", BROWSER)

-- Input: UK keyboard on every machine, and normal pointer acceleration instead of CachyOS's flat profile
hl.config({
    input = {
        kb_layout = "gb",
        accel_profile = "adaptive",
        -- Natural (inverted) scrolling on the touchpad only, like end-4; mouse wheels stay traditional
        touchpad = { natural_scroll = true },
    },
})

-- Dolphin: CachyOS floats it; tile it like other apps (its dialogs still float)
hl.window_rule({ match = { class = "^(org\\.kde\\.dolphin)$" }, float = false })

-- Revise (only on machines that have it)
if exists(HOME .. "/.local/bin/revise") then
    hl.bind("SUPER + Y", hl.dsp.exec_cmd("~/.local/bin/revise"), { description = "Revise: open the dashboard" })
    hl.bind("SUPER + SHIFT + Y", hl.dsp.exec_cmd("~/.local/bin/revise again"), { description = "Revise: reopen this block" })
    hl.bind("SUPER + CTRL + Y", hl.dsp.exec_cmd("~/.local/bin/revise later"), { description = "Revise: move today's subject to tomorrow" })
end
-- HELIOS (only on machines that have it): its installer owns user/helios.lua, so updates here never clobber it
if exists(HOME .. "/.config/hypr/user/helios.lua") then dofile(HOME .. "/.config/hypr/user/helios.lua") end
-- Scroll direction for workspace switching, as before
hl.unbind("SUPER + mouse_up")
hl.unbind("SUPER + mouse_down")
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "m-1" }))
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "m+1" }))

-- Screenshots like end-4: drag to crop, or click a highlighted window to grab just that
hl.unbind("SUPER + SHIFT + S")
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("grimblast --freeze --notify copysave area ~/Pictures/Screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png"), { description = "Screenshot: region or window" })
-- The special-workspace move that used Super+Shift+S now lives here
hl.bind("SUPER + ALT + S", hl.dsp.window.move({ workspace = "special" }), { description = "Move window to special workspace" })

-- Workspaces like end-4: Super+1..0 jumps to workspace 1-10,
-- Super+Shift+N moves the window there and follows, Super+Alt+N sends it without following.
-- 1-5 live on the laptop and 6-10 on the ultrawide (user/hosts/<hostname>.lua).
local function code(i) return "code:" .. (9 + i) end  -- 1..9 -> 10..18, 10 (the 0 key) -> 19
for i = 1, 10 do
    for _, mods in ipairs({ "SUPER", "SUPER + SHIFT", "SUPER + ALT" }) do
        hl.unbind(mods .. " + " .. code(i))
    end
    hl.bind("SUPER + " .. code(i), hl.dsp.focus({ workspace = i }), { description = "Workspace: focus " .. i })
    hl.bind("SUPER + SHIFT + " .. code(i), hl.dsp.window.move({ workspace = i }), { description = "Window: move to workspace " .. i })
    hl.bind("SUPER + ALT + " .. code(i), hl.dsp.window.move({ workspace = i, follow = false }), { description = "Window: send to workspace " .. i })
end

-- Tap Super on its own to open the launcher, like end-4 (Super+Space still works).
-- Release binds are cancelled if another key is pressed while Super is held, so Super+1 etc. don't trigger it.
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"), { release = true, description = "Launcher (tap Super)" })
hl.bind("SUPER + SUPER_R", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"), { release = true })

-- Ctrl+Alt+Delete opens the session menu (lock, log out, suspend, reboot, shut down)
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("noctalia msg panel-toggle session"), { description = "Session menu" })

-- Ctrl+Super+T opens Noctalia's wallpaper picker
hl.bind("CTRL + SUPER + T", hl.dsp.exec_cmd("noctalia msg panel-toggle wallpaper"), { description = "Wallpaper picker" })

-- Super+Shift+T: drag a region (or click a window) and copy its text, OCR'd offline with tesseract
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("~/.local/bin/ocr-region"), { description = "OCR: copy text from a region" })

-- Monitor utility (nwg-displays) opens as a floating settings window
hl.window_rule({ match = { class = "^(nwg-displays)$" }, float = true, center = true, size = { "monitor_w*0.6", "monitor_h*0.7" } })

-- Lock screen: qylock (Quickshell) via hypridle. Super+L and the session menu send
-- `loginctl lock-session`; hypridle runs ~/.local/bin/lock-screen and also locks before sleep.
-- allow_session_lock_restore lets a crashed lock screen be restarted while staying locked.
hl.config({ misc = { allow_session_lock_restore = true } })
hl.on("hyprland.start", function () hl.exec_cmd("hypridle") end)
hl.unbind("SUPER + L")
hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock screen" })

-- Glass desktop widgets: blur what shows through their translucent backgrounds
-- (CachyOS's Noctalia blur rule doesn't cover desktop widget layers)
hl.layer_rule({
    name = "noctalia-desktop-widgets",
    match = { namespace = "^noctalia-desktop-widget-.+$" },
    blur = true,
    ignore_alpha = 0.05,
})

-- Glassier blur (applies to everything blurred: bar, panels, desktop widgets, kitty):
-- lighter than CachyOS's 4 passes so shapes stay faintly visible, with grain and colour
hl.config({
    decoration = {
        blur = {
            passes = 3,
            size = 4,
            noise = 0.02,
            contrast = 1.12,
            vibrancy = 0.55,
            brightness = 1.02,
        },
    },
})

-- Finalist timers: small pinned floating windows stacked down the right edge
hl.window_rule({ match = { title = "^Finalist timer.*$" }, float = true, pin = true, no_initial_focus = true,
    no_shadow = true, border_size = 0, no_anim = true, size = { "320", "78" } })
for i = 0, 7 do
    hl.window_rule({ match = { title = "^Finalist timer " .. i .. ":.*$" }, move = { "(monitor_w-344)", tostring(64 + 90 * i) } })
end

-- Desktop widgets on every monitor: copies follow the originals, and appear/disappear with monitors
local widgets_everywhere = "sleep 2; " .. HOME .. "/.local/bin/desktop-widgets-everywhere"
for _, ev in ipairs({ "hyprland.start", "monitor.added", "monitor.removed" }) do
    hl.on(ev, function () hl.exec_cmd(widgets_everywhere) end)
end

-- Workspaces follow whatever monitors are plugged in, on any port (HDMI, USB-C, a dock...):
-- 1-10 are split across the main screen first, then the others left to right (two screens =
-- 1-5 and 6-10). Unplugging moves a screen's workspaces, windows and all, to the ones left.
-- Runs at login and on every plug/unplug. Main screen = PRIMARY_MONITOR (a port or "desc:"
-- name from the host file) when connected, else a built-in panel, else the leftmost.
local ws_rules = {}
function SYNS_PLACE_WORKSPACES()
    local mons = {}
    for _, m in ipairs(hl.get_monitors()) do
        if m.enabled ~= false and not m.is_mirror then mons[#mons + 1] = m end
    end
    if #mons == 0 then return end
    local function is_main(m)
        local p = PRIMARY_MONITOR or ""
        return p ~= "" and (m.name == p or (p:sub(1, 5) == "desc:" and m.description:find(p:sub(6), 1, true) == 1))
    end
    local function rank(m)
        if is_main(m) then return 0 end
        if m.name:match("^eDP") or m.name:match("^LVDS") or m.name:match("^DSI") then return 1 end
        return 2
    end
    table.sort(mons, function (a, b)
        if rank(a) ~= rank(b) then return rank(a) < rank(b) end
        if a.x ~= b.x then return a.x < b.x end
        return a.y < b.y
    end)

    local focused = hl.get_active_workspace()
    local per = math.ceil(10 / #mons)
    for _, r in ipairs(ws_rules) do pcall(function () r:set_enabled(false) end) end
    ws_rules = {}
    for ws = 1, 10 do
        local mon = mons[math.min(#mons, math.floor((ws - 1) / per) + 1)]
        ws_rules[#ws_rules + 1] = hl.workspace_rule({ workspace = tostring(ws), monitor = mon.name, default = ((ws - 1) % per == 0), persistent = true })
        local w = hl.get_workspace(tostring(ws))
        if w and w.monitor and w.monitor.name ~= mon.name then
            hl.dispatch(hl.dsp.workspace.move({ workspace = tostring(ws), monitor = mon.name }))
        end
    end
    -- Show each screen its first workspace if it's sitting on a stray one (e.g. 11), and put
    -- focus back where it was
    for i, mon in ipairs(mons) do
        local first = (i - 1) * per + 1
        local cur = mon.active_workspace
        if first <= 10 and cur and cur.id and (cur.id > 10 or cur.id < 1) then
            hl.dispatch(hl.dsp.focus({ monitor = mon.name }))
            hl.dispatch(hl.dsp.focus({ workspace = tostring(first) }))
        end
    end
    if focused and focused.name then hl.dispatch(hl.dsp.focus({ workspace = focused.name })) end
end
for _, ev in ipairs({ "hyprland.start", "monitor.added", "monitor.removed" }) do
    -- Delayed slightly so Hyprland has finished setting the monitor up
    hl.on(ev, function () hl.exec_cmd("sleep 1; hyprctl eval 'SYNS_PLACE_WORKSPACES()'") end)
end

-- Jump to an app when it asks for attention (e.g. the browser after opening a link), as in end-4
hl.config({ misc = { focus_on_activate = true } })
