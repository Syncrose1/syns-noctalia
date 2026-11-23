-- Machine-specific settings for LAPTOP-CACHY01 (Dell laptop + iiyama ultrawide).
-- hyprland.lua calls vars() right after CachyOS's variables, and setup() after everything else.

local M = {}

function M.vars()
    MONITOR1 = "eDP-1"
    MONITOR2 = "desc:iiyama Corporation PL3467WQ"   -- ultrawide, on HDMI or USB-C
    PRIMARY_MONITOR = MONITOR1
end

function M.setup()
    -- Monitors are matched by model (desc:), so they work on any port.
    -- Laptop panel
    hl.monitor({ output = "desc:AU Optronics 0x5491", mode = "1920x1080@60.05", position = "0x0", scale = 1 })
    -- iiyama ultrawide: its EDID wrongly advertises 4K as preferred, so pin the native resolution
    -- (at the fastest refresh the cable allows: 30Hz over HDMI, up to 100Hz over USB-C/DisplayPort)
    hl.monitor({ output = "desc:iiyama Corporation PL3467WQ", mode = "3440x1440", position = "auto-right", scale = 1 })
    -- Any other monitor: highest resolution, placed to the right, scale auto-detected
    hl.monitor({ output = "", mode = "highres", position = "auto-right", scale = "auto" })

    -- Workspaces: 1-5 on the laptop, 6-10 on whatever second screen is plugged in (user/shared.lua)
end

return M
