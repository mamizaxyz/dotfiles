# Copyright (c) 2010 Aldo Cortesi
# Copyright (c) 2010, 2014 dequis
# Copyright (c) 2012 Randall Ma
# Copyright (c) 2012-2014 Tycho Andersen
# Copyright (c) 2012 Craig Barnes
# Copyright (c) 2013 horsik
# Copyright (c) 2013 Tao Sauvage
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import os
import subprocess
from libqtile import bar, layout, widget, qtile, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal

mod = "mod4"
terminal = os.environ['TERMINAL']
browser = os.environ['BROWSER']

keys = [
    Key([mod], "w", lazy.spawn(browser), desc="Web browser"),
    Key([mod], "e", lazy.spawn("emacs"), desc="Emacs"),
    Key([mod], "r", lazy.spawn(terminal + " -e lfub"), desc="Terminal file browser"),
    Key([mod], "d", lazy.spawn("rofi -show drun"), desc="Run launcher"),



    Key([mod], "f", lazy.window.toggle_fullscreen(), desc="Toggle fullscreen"),
    Key([mod, "shift"], "space", lazy.window.toggle_floating(), desc="Toggle floating"),


    # A list of available commands that can be bound to keys can be found
    # at https://docs.qtile.org/en/latest/manual/config/lazy.html
    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    # Move windows between left/right columns or move up/down in current stack.
    # Moving out of range in Columns layout will create new column.
    Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"),
    Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move window to the right"),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key([mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "w", lazy.spawn("brave"), desc="Launch terminal"),
    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    Key([mod, "control"], "r", lazy.reload_config(), desc="Reload the config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    # Key([mod], "r", lazy.spawncmd(), desc="Spawn a command using a prompt widget"),
]

groups = [Group(i) for i in "1234567890"]

def go_to_group(name: str) -> callable:
    def _inner(qtile: qtile) -> None:
        if len(qtile.screens) == 1:
            qtile.groups_map[name].cmd_toscreen()
            return
        if name in "12345":
            qtile.focus_screen(0)
            qtile.groups_map[name].cmd_toscreen()
        else:
            qtile.focus_screen(1)
            qtile.groups_map[name].cmd_toscreen()

    return _inner

for i in groups:
    keys.append(Key([mod], i.name, lazy.function(go_to_group(i.name))))
    keys.append(Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
                  desc="move focused window to group {}".format(i.name)))

layouts = [
    layout.Tile(
        margin = 10,
        border_width = 2,
        border_focus = "#bf93f9",
        border_normal = "#282c34"
    ),
    layout.Columns(border_focus_stack=["#d75f5f", "#8f3d3d"], border_width=4),
    layout.Max(),
    # Try more layouts by unleashing below layouts.
    # layout.Stack(num_stacks=2),
    # layout.Bsp(),
    # layout.Matrix(),
    # layout.MonadTall(),
    # layout.MonadWide(),
    # layout.RatioTile(),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
]

widget_defaults = dict(
    background = "#282c34",
    font="Fira Code",
    fontsize=16,
    padding=3,
)
extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.GroupBox(
                    highlight_method = "line",
                    disable_drag = True,
                    this_current_screen_border = "#bf93f9",
                    inactive = "#FFFFFF",
                    hide_unused = True,
                    rounded = False
                ),
                widget.LaunchBar(
                    default_icon = "/usr/share/icons/hicolor/256x256/apps/brave-desktop.png",
                    progs = [("brave", "brave" , "brave")]
                ),
                widget.LaunchBar(
                    default_icon = "/usr/share/icons/hicolor/128x128/apps/emacs.png",
                    progs = [("emacs", "emacs" , "emacs")]
                ),
                widget.CurrentLayout(),
                widget.Prompt(),
                widget.TaskList(
                    highlight_method = "block",
                    unfocused_border = "#1a1a1a",
                    border = "#bf93f9",
                    rounded = False
                ),
                widget.PulseVolume(
                    emoji = True
                ),
                widget.PulseVolume(),
                widget.CheckUpdates(
                    custom_command = "pacman -Qu",
                    execute = terminal + " -e sb-popupgrade",
                    display_format = "/📦 {updates}"
                ),
                widget.TextBox(text = "/"),
                widget.Battery(
                    battery = "BAT1",
                    format = "{char} {percent:2.0%} ({hour:d}:{min:02d})",
                    full_char = "⚡",
                    charge_char = "🔌",
                    discharge_char = "🔋",
                    empty_char = "🪫",
                    unknown_char = "🤔",
                    notify_below = 10, # Investigate
                    low_percentage = 0.25,
                    low_foreground = "#FF0000",
                    update_interval = 1,
                    mouse_callbacks = {
                        "Button4": lambda : qtile.cmd_spawn("xbacklight -inc 10"),
                        "Button5": lambda : qtile.cmd_spawn("xbacklight -dec 10"),
                    }
                ),
                widget.TextBox(text = "/"),
                widget.Net(
                    interface = "wlo1",
                    format = "👇{down} 👆{up:0}"
                ),
                widget.TextBox(text = "/"),
                widget.Clock(format="%Y %b %e (%a) %I:%M %p"),
                widget.Systray(),
                widget.CurrentScreen()
            ],
            32,
            # border_width=[2, 0, 2, 0],  # Draw top and bottom borders
            # border_color=["ff00ff", "000000", "ff00ff", "000000"]  # Borders are magenta
        ),
    ),
    Screen(
        top=bar.Bar(
            [
                widget.GroupBox(
                    highlight_method = "line",
                    disable_drag = True,
                    this_current_screen_border = "#bf93f9",
                    inactive = "#FFFFFF",
                    hide_unused = True,
                    rounded = False
                ),
                widget.LaunchBar(
                    default_icon = "/usr/share/icons/hicolor/256x256/apps/brave-desktop.png",
                    progs = [("brave", "brave" , "brave")]
                ),
                widget.LaunchBar(
                    default_icon = "/usr/share/icons/hicolor/128x128/apps/emacs.png",
                    progs = [("emacs", "emacs" , "emacs")]
                ),
                widget.CurrentLayout(),
                widget.Prompt(),
                widget.TaskList(
                    highlight_method = "block",
                    unfocused_border = "#1a1a1a",
                    border = "#bf93f9",
                    rounded = False
                ),
                widget.PulseVolume(
                    emoji = True
                ),
                widget.PulseVolume(),
                widget.CheckUpdates(
                    custom_command = "pacman -Qu",
                    execute = terminal + " -e sb-popupgrade",
                    display_format = "/📦 {updates}"
                ),
                widget.TextBox(text = "/"),
                widget.Battery(
                    battery = "BAT1",
                    format = "{char} {percent:2.0%} ({hour:d}:{min:02d})",
                    full_char = "⚡",
                    charge_char = "🔌",
                    discharge_char = "🔋",
                    empty_char = "🪫",
                    unknown_char = "🤔",
                    notify_below = 10, # Investigate
                    low_percentage = 0.25,
                    low_foreground = "#FF0000",
                    update_interval = 1,
                    mouse_callbacks = {
                        "Button4": lambda : qtile.cmd_spawn("xbacklight -inc 10"),
                        "Button5": lambda : qtile.cmd_spawn("xbacklight -dec 10"),
                    }
                ),
                widget.TextBox(text = "/"),
                widget.Net(
                    interface = "wlo1",
                    format = "👇{down} 👆{up:0}"
                ),
                widget.TextBox(text = "/"),
                widget.Clock(format="%Y %b %e (%a) %I:%M %p"),
                widget.Systray(),
                widget.CurrentScreen()
            ],
            32,
            # border_width=[2, 0, 2, 0],  # Draw top and bottom borders
            # border_color=["ff00ff", "000000", "ff00ff", "000000"]  # Borders are magenta
        ),
    ),
]

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(), start=lazy.window.get_position()),
    Drag([mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
    ],
    border_width = 2,
    border_focus = "#bf93f9",
    border_normal = "#282c34"
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"

@hook.subscribe.startup_once
def autostart():
    subprocess.Popen([os.path.expanduser("~/.config/qtile/autostart.sh")])
