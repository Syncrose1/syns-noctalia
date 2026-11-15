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

-- Input: UK keyboard, and normal pointer acceleration instead of CachyOS's flat profile
hl.config({
    input = {
        kb_layout = "gb",
        accel_profile = "adaptive",
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
