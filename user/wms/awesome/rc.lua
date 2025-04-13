local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup")
local naughty = require("naughty")
require("awful.hotkeys_popup.keys")

local ez = require("awesome-ez")
local json = require("cjson")

require("client")
local setup_tasklist = require("tasklist")

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

awful.layout.layouts = {
    awful.layout.suit.floating,
}

local main_menu = awful.menu({ items = wm_common.app_menu })
setup_tasklist(main_menu)

root.buttons(gears.table.join(awful.button({}, 3, function()
    main_menu:toggle()
end)))

global_keys = gears.table.join(
    awful.key(
        { "Mod4" },
        "s",
        hotkeys_popup.show_help,
        { description = "show help", group = "awesome" }
    ),
    awful.key(
        { "Mod4", "Control" },
        "r",
        awesome.restart,
        { description = "reload awesome", group = "awesome" }
    ),
    table.unpack(ez.keytable(wm_common.global_application_keybinds))
)

root.keys(global_keys)

client_keys = gears.table.join(awful.key({ "Mod4", "Control" }, "t", function(c)
    c.ontop = not c.ontop
end, { description = "toggle keep on top", group = "client" }))

client_buttons = gears.table.join(
    awful.button({}, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
    end),
    awful.button({ "Mod1" }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        if c.maximized then
            c.maximized = false
            c:geometry(awful.placement.maximize())
        end
        awful.mouse.client.move(c)
    end)
)

awful.rules.rules = {
    {
        rule = {},
        properties = {
            floating = true,
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = client_keys,
            buttons = client_buttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap + awful.placement.no_offscreen,
        },
    },

    {
        rule_any = { class = wm_common.maximized_wm_classes },
        properties = { maximized = true },
    },

    {
        rule_any = { type = { "normal", "dialog" } },
        properties = { titlebars_enabled = true },
    },

    {
        rule = { class = "io-gitlab-wylieyyyy-piptube-AppKt" },
        properties = {
            focusable = false,
            placement = awful.placement.restore,
        },
    },
}
