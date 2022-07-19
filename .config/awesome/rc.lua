-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
-- Notification library
local _dbus = dbus; dbus = nil -- Disable naughty
local naughty = require("naughty")
dbus = _dbus -- Disable naughty
local menubar = require("menubar")
local freedesktop = require("freedesktop")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")


-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_themes_dir() .. "xresources/theme.lua")
beautiful.font = "Fira Code 12"
beautiful.hotkeys_font = "Iosevka 14"
beautiful.hotkeys_description_font = "Iosevka 12"
beautiful.menu_font = "Iosevka 12"
beautiful.useless_gap = 10
beautiful.border_width = 2
beautiful.border_focus = "#bf93f9"
beautiful.taglist_squares_sel = ""
beautiful.taglist_squares_unsel = ""
beautiful.tasklist_bg_normal = "#282a36"
beautiful.menu_width = 350
beautiful.icon_theme = "Papirus"

-- This is used later as the default terminal and editor to run.
terminal = os.getenv("TERMINAL") or "alacritty"
editor = os.getenv("EDITOR") or "vim"
browser = os.getenv("BROWSER") or "firefox"
editor_cmd = terminal .. " -e " .. editor

local show_desktop = false

modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.floating,
    -- awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    -- awful.layout.suit.fair,
    -- awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    -- awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    -- awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
mainmenu = freedesktop.menu.build()

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibar
-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  c:emit_signal(
                                                      "request::activate",
                                                      "tasklist",
                                                      {raise = true}
                                                  )
                                              end
                                          end),
                     awful.button({ }, 3, function()
                                              awful.menu.client_list({ theme = { width = 250 } })
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

local function set_wallpaper()
    awful.spawn("setbg")
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

local Battery = require("battery")

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper()

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))

    s.mywibox = awful.wibar({ position = "top", screen = s, height = 36 })
    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        {
            layout = wibox.layout.fixed.horizontal,
            awful.widget.taglist {
                screen  = s,
                filter  = function (t) return t.selected or #t:clients() > 0 end,
                buttons = taglist_buttons,
            },
            wibox.widget.textbox(" | "),
            s.mylayoutbox,
            wibox.widget.textbox(" | "),
        },
        awful.widget.tasklist {
            screen  = s,
            filter  = awful.widget.tasklist.filter.currenttags,
            buttons = tasklist_buttons,
            layout = {
                layout = wibox.layout.fixed.horizontal,
                spacing = 2,
            }
        },
        {
            layout = wibox.layout.fixed.horizontal,
            awful.widget.keyboardlayout(),
            wibox.widget.textbox(" | "),
            -- Brightness({
            --         type = "icon_and_text",
            --         program = "xbacklight",
            --         step = 10,
            --         base = 100,
            --         -- timeout = 10,
            -- }),
            -- wibox.widget.textbox(" | "),
            Battery({
                    timeout = 1,
                    show_current_level = true,
                    size = 30,
                    font = "Iosevka",
            }),
            wibox.widget.textbox(" | "),
            wibox.widget.textclock('%Y %b %e (%a) %H:%M%p'),
            wibox.widget.textbox(" | "),
            wibox.widget.systray(),
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 3, function () mainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev),
    awful.button({ }, 8, awful.tag.viewprev),
    awful.button({ }, 9, awful.tag.viewnext)
))
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    -- Help
    awful.key({ modkey }, "F1", hotkeys_popup.show_help, { description="show help", group="awesome" }),

    -- Screenshot
    awful.key({         }, "Print", function () awful.spawn.with_shell("scrot    ~/pix/$(date '+%y%m%d-%H%M-%S').png") end, { description="Take screenshot", group="Actions" }),
    awful.key({ "Shift" }, "Print", function () awful.spawn.with_shell("scrot -s ~/pix/$(date '+%y%m%d-%H%M-%S').png") end, { description="Take screenshot of region", group="Actions" }),

    -- System actions
    awful.key({ modkey }, "BackSpace", function () awful.spawn.with_shell("sysact") end, { description="System Actions", group="Actions" }),

    -- Toggle statusbar
    awful.key({ modkey }, "b",
        function ()
            myscreen = awful.screen.focused()
            myscreen.mywibox.visible = not myscreen.mywibox.visible
        end,
        { description = "Toggle statusbar", group = "client"}
    ),

    -- Change window focus
    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        { description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        { description = "focus previous by index", group = "client"}
    ),


    -- Open mainmenu
    awful.key({ modkey }, "/", function () mainmenu:show() end, { description = "show main menu", group = "awesome" }),

    -- Open applications
    awful.key({ modkey }, "Return", function () awful.spawn(terminal)               end, { description = "open a terminal",  group = "Applications" }),
    awful.key({ modkey }, "w",      function () awful.spawn(browser)                end, { description = "Browser",          group = "Applications" }),
    awful.key({ modkey }, "e",      function () awful.spawn("emacs")                end, { description = "Emacs",            group = "Applications" }),
    awful.key({ modkey }, "r",      function () awful.spawn(terminal .. " -e lfub") end, { description = "LF",               group = "Applications" }),
    awful.key({ modkey }, "d",      function () awful.spawn("rofi -show drun")      end, { description = "Rofi Launcher",    group = "Applications" }),
    awful.key({ modkey }, "t",      function () awful.spawn("telegram-desktop")     end, { description = "Telegram Desktop", group = "Applications" }),

    awful.key({ modkey }, "=",      function () awful.spawn("pamixer --allow-boost -i 5")     end, { description = "Telegram Desktop", group = "Applications" }),
    awful.key({ modkey, "Shift" }, "=",      function () awful.spawn("pamixer --allow-boost -i 15")     end, { description = "Telegram Desktop", group = "Applications" }),
    awful.key({ modkey }, "-",      function () awful.spawn("pamixer --allow-boost -d 5")     end, { description = "Telegram Desktop", group = "Applications" }),
    awful.key({ modkey, "Shift" }, "-",      function () awful.spawn("pamixer --allow-boost -d 15")     end, { description = "Telegram Desktop", group = "Applications" }),

    awful.key({ modkey }, "]",      function () awful.spawn("xbacklight -inc 10")     end, { description = "Telegram Desktop", group = "Applications" }),
    awful.key({ modkey, "Shift" }, "]",      function () awful.spawn("xbacklight -inc 20")     end, { description = "Telegram Desktop", group = "Applications" }),
    awful.key({ modkey }, "[",      function () awful.spawn("xbacklight -dec 10")     end, { description = "Telegram Desktop", group = "Applications" }),
    awful.key({ modkey, "Shift" }, "[",      function () awful.spawn("xbacklight -dec 20")     end, { description = "Telegram Desktop", group = "Applications" }),

    awful.key({ modkey, "Shift" }, "s", function () awful.spawn.with_shell("(synclient | grep 'TouchpadOff.*1' && synclient TouchpadOff=0) || synclient TouchpadOff=1")     end, { description = "Telegram Desktop", group = "Applications" }),


    awful.key({ modkey, "Shift" }, "i", function () awful.spawn("brave --incognito") end, { description = "Toggle VPN", group = "client" }),
    awful.key({ modkey, "Shift" }, "p", function () awful.spawn("firefox --private-window") end, { description = "Toggle VPN", group = "client" }),
    awful.key({ modkey, "Shift" }, "v", function () awful.spawn("vpntoggle") end, { description = "Toggle VPN", group = "client" }),
    awful.key({ modkey, "Shift" }, "x", function () awful.spawn.with_shell("setbg ~/.local/share/wallpapers") end, { description = "Choose random wallpaper", group = "client" }),

    -- Toggle titlebar
    awful.key({ modkey, "Control" }, "t", function () awful.titlebar.toggle(client.focus) end, { description="Toggle titlebar", group="awesome" }),

    -- Layout manipulation
    awful.key({ modkey, "Shift" }, "j",   function () awful.client.swap.byidx(  1)    end, { description = "swap with next client by index", group = "client" }),
    awful.key({ modkey, "Shift" }, "k",   function () awful.client.swap.byidx( -1)    end, { description = "swap with previous client by index", group = "client" }),
    -- awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end, { description = "focus the next screen", group = "screen" }),
    -- awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end, { description = "focus the previous screen", group = "screen" }),

    -- Change focus between screens
    awful.key({ modkey }, ",", function () awful.screen.focus_relative( 1) end, { description = "focus the next screen",     group = "screen" }),
    awful.key({ modkey }, ".", function () awful.screen.focus_relative(-1) end, { description = "focus the previous screen", group = "screen" }),

    awful.key({ modkey, "Control" }, "r", awesome.restart, { description = "reload awesome", group = "awesome" }),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit, { description = "quit awesome", group = "awesome" }),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              { description = "increase master width factor", group = "layout" }),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              { description = "decrease master width factor", group = "layout" }),

    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              { description = "increase the number of master clients", group = "layout" }),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              { description = "decrease the number of master clients", group = "layout" }),

    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              { description = "increase the number of columns", group = "layout" }),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              { description = "decrease the number of columns", group = "layout" }),

    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              { description = "select next", group = "layout" }),

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                    c:emit_signal(
                        "request::activate", "key.unminimize", {raise = true}
                    )
                  end
              end,
              { description = "restore minimized", group = "client" })
)

clientkeys = gears.table.join(

    awful.key({ modkey }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        { description = "toggle fullscreen", group = "client" }),

    awful.key({ modkey }, "q", function (c) c:kill() end, { description = "close", group = "client" }),

    awful.key({ modkey }, "s", function (c) c.sticky = not c.sticky end, { description = "toggle floating", group = "client" }),
    awful.key({ modkey, "Shift" }, "space", awful.client.floating.toggle, { description = "toggle floating", group = "client" }),
    awful.key({ modkey, "Shift" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
              { description = "move to master", group = "client" }),

    awful.key({ modkey, "Shift" }, ",", function (c) c:move_to_screen() end, { description = "move to screen", group = "client" }),
    awful.key({ modkey, "Shift" }, ".", function (c) c:move_to_screen() end, { description = "move to screen", group = "client" }),

    awful.key({ modkey, "Shift" }, "t", function (c) c.ontop = not c.ontop end, { description = "toggle keep on top", group = "client" }),

    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end ,
        { description = "minimize", group = "client" }),

    awful.key({ modkey, "Control" }, "d",
        function (c)
            if show_desktop then
                for _, c in ipairs(client.get()) do
                    c:emit_signal(
                        "request::activate", "key.unminimize", {raise = true}
                    )
                end
                show_desktop = false
            else
                for _, c in ipairs(client.get()) do
                    c.minimized = true
                end
                show_desktop = true
            end
        end,
        { description = "toggle desktop", group = "client" }),



    -- Bindings to move and resize windows
    awful.key({ modkey }, "Down",  function (c) c:relative_move(  0,  20,  0,  0) end, { description = "Rofi Launcher", group = "Applications" }),
    awful.key({ modkey }, "Up",    function (c) c:relative_move(  0, -20,  0,  0) end, { description = "Rofi Launcher", group = "Applications" }),
    awful.key({ modkey }, "Left",  function (c) c:relative_move(-20,   0,  0,  0) end, { description = "Rofi Launcher", group = "Applications" }),
    awful.key({ modkey }, "Right", function (c) c:relative_move( 20,   0,  0,  0) end, { description = "Rofi Launcher", group = "Applications" }),
    awful.key({ modkey, "Shift" }, "Up",    function (c) c:relative_move(  0,   0,   0, -40) end, { description = "Rofi Launcher", group = "Applications" }),
    awful.key({ modkey, "Shift" }, "Down",  function (c) c:relative_move(  0,   0,   0,  40) end, { description = "Rofi Launcher", group = "Applications" }),
    awful.key({ modkey, "Shift" }, "Right", function (c) c:relative_move(  0,   0,  40,   0) end, { description = "Rofi Launcher", group = "Applications" }),
    awful.key({ modkey, "Shift" }, "Left",  function (c) c:relative_move(  0,   0, -40,   0) end, { description = "Rofi Launcher", group = "Applications" })
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  { description = "view tag #"..i, group = "tag" }),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  { description = "toggle tag #" .. i, group = "tag" }),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  { description = "move focused client to tag #"..i, group = "tag" }),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  { description = "toggle focused client on tag #" .. i, group = "tag" })
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
          "pinentry",
        },
        class = {
          "Blueman-manager",
          "TelegramDesktop",
          -- Needs a fixed window size to avoid fingerprinting by screen size.
          "Tor Browser"
        },

        -- Note that the name property shown in xprop might be set slightly after creation of the client
        -- and the name shown there might not match defined rules here.
        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = false }
    },

    -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
    { rule = { },
        properties = {
            placement = awful.placement.centered + awful.placement.no_overlap + awful.placement.no_offscreen
    }}
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            c:emit_signal("request::activate", "titlebar", {raise = true})
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- Autostart
awful.spawn.with_shell("$XDG_CONFIG_HOME/awesome/autostart.sh")
