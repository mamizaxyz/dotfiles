#!/bin/sh

setsid -f xrdb "$HOME/.config/x11/xresources"

xset r rate 300 50

pidof -s picom || setsid -f picom --experimental-backends &

autostart="nm-applet volumeicon screenres unclutter dunst taptoclick"

for p in $autostart; do
        pidof -s "$p" || setsid -f "$p"
done
