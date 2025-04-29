local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local wibox = require("wibox")

client.connect_signal("request::titlebars", function(c)
    if c.requests_no_titlebar then
        return
    end

    local buttons = gears.table.join(
        awful.button({}, 1, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            if c.maximized then
                c.maximized = false
                c:geometry(awful.placement.maximize())
            end
            awful.mouse.client.move(c)
        end),
        awful.button({}, 3, function()
            c:emit_signal("request::activate", "titlebar", { raise = true })
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c):setup({
        {
            awful.titlebar.widget.iconwidget(c),
            awful.titlebar.widget.stickybutton(c),
            layout = wibox.layout.fixed.horizontal,
        },
        {
            {
                align = "center",
                widget = awful.titlebar.widget.titlewidget(c),
            },
            buttons = buttons,
            layout = wibox.layout.flex.horizontal,
        },
        {
            awful.titlebar.widget.minimizebutton(c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.closebutton(c),
            layout = wibox.layout.fixed.horizontal,
        },
        layout = wibox.layout.align.horizontal,
    })
end)

client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
end)

client.connect_signal("unfocus", function(c)
    if not c.ontop then
        c.border_color = beautiful.border_normal
    end
end)

client.connect_signal("property::ontop", function(c)
    c.sticky = c.ontop
    c.border_width = beautiful.border_width * (c.ontop and 5 or 1)
end)
