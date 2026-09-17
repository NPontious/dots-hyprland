hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

local smw_dir = HOME .. "/.config/hypr"
if not package.path:find(smw_dir, 1, true) then
    package.path = package.path .. ";" .. smw_dir .. "/?.lua;" .. smw_dir .. "/?/init.lua"
end

local ok, smw = pcall(require, "plugins.split-monitor-workspaces")
if ok then
    local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
    local numpadkey = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }

    for i = 1, 10 do
        local n = tostring(i % 10)
        local ws = tostring(i)

        -- Unbind default workspace binds to prevent dual dispatch
        hl.unbind("SUPER + " .. n)
        hl.unbind("SUPER + code:" .. numberkey[i])
        hl.unbind("SUPER + code:" .. numpadkey[i])
        hl.unbind("SUPER + ALT + " .. n)
        hl.unbind("SUPER + ALT + code:" .. numpadkey[i])

        -- Switch to workspace N on currently active monitor
        hl.bind("SUPER + " .. n, smw.workspace(ws), { description = "Workspace: Focus " .. i })
        hl.bind("SUPER + code:" .. numberkey[i], smw.workspace(ws))
        hl.bind("SUPER + code:" .. numpadkey[i], smw.workspace(ws))

        -- Send active window to workspace N on current monitor (silent, keep focus)
        hl.bind("SUPER + ALT + " .. n, smw.move_to_workspace_silent(ws), { description = "Window: Send to workspace " .. i })
        hl.bind("SUPER + ALT + code:" .. numpadkey[i], smw.move_to_workspace_silent(ws))
    end

    -- Monitor-scoped workspace cycling (replaces global r+/r- cycling)
    hl.unbind("SUPER + Page_Up")
    hl.unbind("SUPER + Page_Down")
    hl.bind("SUPER + Page_Up", smw.cycle_workspaces("prev"), { description = "Workspace: Prev (monitor)" })
    hl.bind("SUPER + Page_Down", smw.cycle_workspaces("next"), { description = "Workspace: Next (monitor)" })

    -- Empty workspace jump and rogue window grab
    hl.bind("SUPER + E", smw.workspace("empty"), { description = "Workspace: Focus first empty" })
    hl.bind("SUPER + ALT + E", smw.move_to_workspace_silent("empty"), { description = "Window: Move to empty workspace" })
    hl.bind("SUPER + SHIFT + G", smw.grab_rogue_windows(), { description = "Window: Grab unmapped windows" })
end
