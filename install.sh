#!/usr/bin/env bash
# install.sh – one-command setup for dev-desktop.
# Run from the repo root: ./install.sh
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Installing packages…"
sudo apt-get update -qq
sudo apt-get install -y \
  i3 kitty rofi scrot feh imagemagick vim xserver-xephyr

echo "==> Creating directories…"
mkdir -p \
  ~/.local/bin \
  ~/.config/i3 \
  ~/.config/kitty \
  ~/.config/rofi \
  ~/wallpapers

echo "==> Copying scripts…"
for f in statusbar.sh sysinfo.sh pomodoro.sh wallpaper-theme.sh; do
  install -m 0755 "$DIR/scripts/$f" ~/.local/bin/"$f"
done

echo "==> Copying configs…"
install -m 0644 "$DIR/config/i3/config"              ~/.config/i3/config
install -m 0644 "$DIR/config/kitty/kitty.conf"       ~/.config/kitty/kitty.conf
install -m 0644 "$DIR/config/rofi/catppuccin.rasi"   ~/.config/rofi/catppuccin.rasi

echo "==> Ensuring notes file exists…"
touch ~/notes.md

echo ""
echo "Done!  To start:"
echo ""
echo "  # In WSL2 / Xephyr:"
echo "  sudo apt install -y xserver-xephyr   # if not already installed"
echo "  Xephyr :1 -screen 1280x720 &"
echo "  DISPLAY=:1 i3"
echo ""
echo "  # On a real Linux desktop: log in to an i3 session."
echo "  # Then press Mod+Shift+r to reload the config."
