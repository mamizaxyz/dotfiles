local awful = require("awful")
local watch = require("awful.widget.watch")
local wibox = require("wibox")
local gfs = require("gears.filesystem")
local gears = require("gears")
local dpi = require('beautiful').xresources.apply_dpi

-- acpi sample outputs
-- Battery 0: Discharging, 75%, 01:51:38 remaining
-- Battery 0: Charging, 53%, 00:57:43 until charged

local HOME = os.getenv("HOME")
local WIDGET_DIR = HOME .. '/.config/awesome/awesome-wm-widgets/battery-widget'

local battery_widget = {}
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

    battery_widget = wibox.widget {
        level_widget,
        layout = wibox.layout.fixed.horizontal,
    }


    local last_battery_check = os.time()
    local batteryType = "🔋"

    watch("acpi -i", timeout,
    function(widget, stdout)
        local battery_info = {}
        local capacities = {}
        for s in stdout:gmatch("[^\r\n]+") do
            local status, charge_str, _ = string.match(s, '.+: ([%a%s]+), (%d?%d?%d)%%,?(.*)')
            if status ~= nil then
                table.insert(battery_info, {status = status, charge = tonumber(charge_str)})
            else
                local cap_str = string.match(s, '.+:.+last full capacity (%d+)')
                table.insert(capacities, tonumber(cap_str))
            end
        end

        local capacity = 0
        for _, cap in ipairs(capacities) do
            capacity = capacity + cap
        end

        local charge = 0
        local status
        for i, batt in ipairs(battery_info) do
            if capacities[i] ~= nil then
                if batt.charge >= charge then
                    status = batt.status -- use most charged battery status
                    -- this is arbitrary, and maybe another metric should be used
                end

                charge = charge + batt.charge * capacities[i]
            end
        end
        charge = charge / capacity

        level_widget.text = string.format('%s%d%%', batteryType, charge)

        if (charge >= 1 and charge < 15) then batteryType = "🪫"
        elseif (charge >= 15 and charge < 100) then batteryType = "🔋"
        elseif (charge == 100) then batteryType = "⚡"
        end

        if status == 'Charging' then
            batteryType = '🔌'
        else
            batteryType = "🔋"
        end
    end)

    battery_widget:buttons(gears.table.join(
                               awful.button({ }, 5, function() awful.spawn("xbacklight -dec 10") end),
                               awful.button({ }, 4, function() awful.spawn("xbacklight -inc 10") end)))

    return wibox.container.margin(battery_widget, margin_left, margin_right)
end

return setmetatable(battery_widget, { __call = function(_, ...) return worker(...) end })
