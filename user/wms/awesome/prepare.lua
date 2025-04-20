local awful = require("awful")

local beautiful = require("beautiful")
local gears = require("gears")
local naughty = require("naughty")

local json = require("cjson")

if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors,
    })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        if in_error then
            return
        end
        in_error = true

        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err),
        })
        in_error = false
    end)
end

beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

local wm_common_file = io.open(gears.filesystem.get_configuration_dir() .. "wm-common.json", "r")
local wm_common = json.decode(wm_common_file:read("*a"))
wm_common_file:close()

for k, v in pairs(wm_common.global_application_keybinds) do
    wm_common.global_application_keybinds[k] = { awful.spawn, v }
end

return wm_common
