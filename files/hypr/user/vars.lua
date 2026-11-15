-- Shared variable overrides, loaded right after CachyOS's config/variables.lua
-- (so CachyOS's binds and rules pick them up).

local function exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

if exists("/opt/zen-browser-bin/zen") then
    BROWSER = "/opt/zen-browser-bin/zen"
end
