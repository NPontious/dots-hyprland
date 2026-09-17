-- Split Monitor Workspaces configuration
local smw_dir = HOME .. "/.config/hypr"
if not package.path:find(smw_dir, 1, true) then
    package.path = package.path .. ";" .. smw_dir .. "/?.lua;" .. smw_dir .. "/?/init.lua"
end

local ok, smw = pcall(require, "plugins.split-monitor-workspaces")
if ok then
    smw.setup({
        -- 10 workspaces per monitor (matches Quickshell shownCount = 10)
        workspace_count = 10,
        keep_focused = true,
        enable_persistent_workspaces = true,
        enable_wrapping = true,
        enable_notifications = false,
        -- monitor_priority = { "DP-1", "HDMI-A-1" }, -- Optional: customize monitor order
    })
else
    print("[split-monitor-workspaces] Plugin not found at plugins.split-monitor-workspaces: " .. tostring(smw))
end
