#!/usr/bin/env bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
echo "Installing packages..."
sudo apt update && sudo apt install -y i3 kitty rofi scrot
mkdir -p ~/.local/bin ~/.config/i3 ~/.config/kitty ~/.config/rofi
cp "$DIR"/scripts/*.sh ~/.local/bin/
chmod +x ~/.local/bin/*.sh
cp "$DIR"/config/i3/config ~/.config/i3/config
cp "$DIR"/config/kitty/kitty.conf ~/.config/kitty/kitty.conf
cp "$DIR"/config/rofi/catppuccin.rasi ~/.config/rofi/catppuccin.rasi
echo "Done. Log into an i3 session, or press Mod+Shift+r to reload."
