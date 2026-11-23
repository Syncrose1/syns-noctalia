-- Machine-specific settings for DESKTOP-CACHY02 (main PC: NVIDIA RTX 3060).
-- hyprland.lua calls vars() right after CachyOS's variables, and setup() after everything else.

local M = {}

function M.vars()
    MONITOR1 = "HDMI-A-1"   -- 1080p 120Hz
    MONITOR2 = "DP-1"       -- 3440x1440 165Hz ultrawide, when connected
    PRIMARY_MONITOR = MONITOR1
end

function M.setup()
    -- NVIDIA drives the displays here
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("GBM_BACKEND", "nvidia-drm")
    hl.env("NVD_BACKEND", "direct")
    hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/10_nvidia.json")

    -- Monitors, matched by model so they work on any port (Monitor Settings overrides these)
    hl.monitor({ output = "desc:Invalid Vendor Codename - RTK 0x1920 0x19201080", mode = "1920x1080@119.88", position = "auto-right", scale = 1 })
    hl.monitor({ output = "DP-1", mode = "3440x1440@165.0", position = "auto-left", scale = 1 })
    hl.monitor({ output = "", mode = "preferred", position = "auto-right", scale = "auto" })

    -- Workspaces: 1-5 on the 1080p screen, 6-10 on the ultrawide when connected (user/shared.lua)

    -- Personal apps and projects on this PC
    hl.bind("SUPER + R", hl.dsp.exec_cmd("obsidian"), { description = "Open Obsidian" })
    hl.bind("CTRL + SUPER + Z", hl.dsp.exec_cmd("qs -p ~/Contract/body/shell.qml ipc call body toggle"), { description = "Contract: toggle body" })
    hl.bind("ALT + Z", hl.dsp.exec_cmd("qs -p ~/POLARIS/body/shell.qml ipc call solis-body toggle"), { description = "Toggle Solis's glyph face" })
    hl.layer_rule({ match = { namespace = "contract:body" }, blur = true, ignore_alpha = 0.05, xray = false })
    hl.layer_rule({ match = { namespace = "solis:body" }, ignore_alpha = 0.05, xray = false })
end

return M
