local awful = require("awful")
local common = require("awful.widget.common")
local gears = require("gears")
local wibox = require("wibox")

local is_kill = false

local tasklist_buttons = gears.table.join(
    awful.button({}, 1, function(c)
        if c == client.focus then
            c.minimized = true
        else
            c:emit_signal("request::activate", "tasklist", { raise = true })
        end
    end),
    awful.button({}, 3, function(c)
        is_kill = true
        c:kill()
    end)
)

local function focus_last_in_history(screen, clients)
    local has_any_focused = false
    for _, c in ipairs(clients) do
        if client.focus == c then
            has_any_focused = true
            break
        end
    end

    local next_focus_client = awful.client.focus.history.get(screen, 0)
    if (not has_any_focused) and (next_focus_client ~= nil) then
        next_focus_client:emit_signal("request::activate", "history", { raise = true })
    end
end

return function(main_menu)
    awful.screen.connect_for_each_screen(function(s)
        awful.tag({ "1", "2" }, s, awful.layout.layouts[1])

        local tasklist_layout = wibox.layout.flex.horizontal()
        tasklist_layout.max_widget_size = 300

        s.tasklist = awful.widget.tasklist({
            screen = s,
            filter = awful.widget.tasklist.filter.currenttags,
            buttons = tasklist_buttons,
            layout = tasklist_layout,
            update_function = function(w, buttons, label, data, clients, ...)
                focus_last_in_history(s, clients)
                common.list_update(w, buttons, label, data, clients, ...)
            end,

            style = {
                shape = function(cr, width, height)
                    gears.shape.rounded_rect(cr, width, height, 2)
                end,
            },

            widget_template = {
                {
                    {
                        {
                            {
                                id = "icon_role",
                                widget = wibox.widget.imagebox,
                            },
                            margins = 2,
                            widget = wibox.container.margin,
                        },
                        {
                            id = "text_role",
                            widget = wibox.widget.textbox,
                        },
                        layout = wibox.layout.fixed.horizontal,
                    },
                    id = "background_role",
                    widget = wibox.container.background,
                },
                left = 1,
                top = 2,
                bottom = 2,
                right = 1,
                widget = wibox.container.margin,
            },
        })

        s.wibox = awful.wibar({ position = "top", height = 30, screen = s })

        local tasklist_margin = wibox.container.margin()
        tasklist_margin.right = 50
        tasklist_margin:buttons(gears.table.join(
            awful.button({}, 2, function(c)
                awful.tag.viewnext()
            end),
            awful.button({}, 3, function(c)
                gears.timer.delayed_call(function()
                    if not is_kill then
                        main_menu:toggle()
                    end
                    is_kill = false
                end)
            end)
        ))

        s.wibox:setup({
            layout = wibox.layout.align.horizontal,
            nil,
            {
                s.tasklist,
                widget = tasklist_margin,
            },
            {
                layout = wibox.layout.fixed.horizontal,
                {
                    wibox.widget.systray(),
                    top = 2.5,
                    bottom = 2.5,
                    widget = wibox.container.margin,
                },
                {
                    layout = wibox.layout.fixed.vertical,
                    wibox.widget.textclock('<span size="large" weight="bold">%H:%M</span>'),
                    wibox.widget.textclock("%Y-%m-%d"),
                },
            },
        })
    end)
end
