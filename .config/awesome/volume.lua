local awful = require("awful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local gfs = require("gears.filesystem")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = require('beautiful').xresources.apply_dpi

local volume_widget = {}
local function worker(user_args)
    local args = user_args or {}
    local font = args.font or beautiful.font
    local margin_left = args.margin_left or 0
    local margin_right = args.margin_right or 0
    local timeout = args.timeout or 10
    local level_widget = wibox.widget {
        font = font,
        widget = wibox.widget.textbox
    }
    volume_widget = wibox.widget {
        level_widget,
        layout = wibox.layout.fixed.horizontal,
    }
    local volume_level = 100
    local volume_icon = ""
    watch("pamixer --get-volume", timeout,
          function (widget, stdout)
              volume_level = tonumber(stdout)
              if (volume_level >= 1 and 25 >= volume_level) then
                  volume_icon = "🔈"
              elseif (volume_level > 25 and 75 >= volume_level) then
                  volume_icon = "🔉"
              elseif (volume_level > 75) then
                  volume_icon = "🔊"
              elseif awful.spawn("pamixer --get-mute") == "true" then
                  volume_level = 0
                  volume_icon = "🔇"
              end
    level_widget.text = string.format('%s%d%%', volume_icon, volume_level)
          end)
    volume_widget:buttons(gears.table.join(
                               awful.button({ }, 5, function() awful.spawn("pamixer --allow-boost -d 5") end),
                               awful.button({ }, 4, function() awful.spawn("pamixer --allow-boost -i 5") end)))
    return wibox.container.margin(volume_widget, margin_left, margin_right)
end
return setmetatable(volume_widget, { __call = function(_, ...) return worker(...) end })
