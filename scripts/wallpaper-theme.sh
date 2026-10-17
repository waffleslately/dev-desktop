#!/usr/bin/env bash
# wallpaper-theme.sh – set wallpaper, extract dominant colour, rewrite
# accent in i3/kitty/rofi, then reload i3.
#
# Usage:  wallpaper-theme.sh [PATH_TO_IMAGE]
# If no image is given and ~/wallpapers/current.jpg exists, that is used.
# If neither exists a gradient PNG is generated with ImageMagick.
#
# Dependencies: feh, imagemagick (convert), i3-msg

set -euo pipefail

I3_CFG="${HOME}/.config/i3/config"
KITTY_CFG="${HOME}/.config/kitty/kitty.conf"
ROFI_CFG="${HOME}/.config/rofi/catppuccin.rasi"
WALLPAPER_DIR="${HOME}/wallpapers"
DEFAULT_WALL="${WALLPAPER_DIR}/default.png"
CURRENT_WALL="${WALLPAPER_DIR}/current.jpg"

# ── 1. Resolve wallpaper path ────────────────────────────────────────────────
WALL=""
if [ -n "${1:-}" ] && [ -f "$1" ]; then
  WALL="$1"
elif [ -f "$CURRENT_WALL" ]; then
  WALL="$CURRENT_WALL"
else
  # Generate a Catppuccin-ish gradient as fallback
  mkdir -p "$WALLPAPER_DIR"
  if command -v convert >/dev/null 2>&1; then
    convert -size 1280x720 \
      gradient:'#1e1e2e-#313244' \
      -fill '#cba6f7' \
      -draw 'rectangle 0,700 1280,720' \
      "$DEFAULT_WALL" 2>/dev/null
    WALL="$DEFAULT_WALL"
  else
    echo "wallpaper-theme: imagemagick not found; cannot generate wallpaper." >&2
    exit 1
  fi
fi

# Keep a copy as "current"
mkdir -p "$WALLPAPER_DIR"
if [ "$WALL" != "$CURRENT_WALL" ]; then
  cp "$WALL" "$CURRENT_WALL" 2>/dev/null || true
fi

# ── 2. Set wallpaper with feh ─────────────────────────────────────────────────
if command -v feh >/dev/null 2>&1; then
  env -u WAYLAND_DISPLAY feh --bg-fill "$WALL"
else
  echo "wallpaper-theme: feh not found, skipping wallpaper set." >&2
fi

# ── 3. Extract dominant colour with ImageMagick ──────────────────────────────
HEX="#89b4fa"   # fallback: Catppuccin blue
if command -v convert >/dev/null 2>&1; then
  DOMINANT=$(convert "$WALL" \
    -resize 64x64 \
    +dither -colors 5 \
    -format "%c" histogram:info:- 2>/dev/null \
    | sort -rn \
    | head -1 \
    | grep -oE '#[0-9a-fA-F]{6}' || echo "")
  if [ -n "$DOMINANT" ]; then
    HEX="$DOMINANT"
  fi
fi

echo "wallpaper-theme: accent colour → $HEX"

# ── 4. Rewrite accent colour in configs ──────────────────────────────────────
# i3: update $accent and $blue lines
if [ -f "$I3_CFG" ]; then
  sed -i -E "s/^(set \\\$(accent|blue)[[:space:]]+)#[0-9a-fA-F]{6}/\1${HEX}/" "$I3_CFG"
fi

# kitty: update color4 (blue), color12 (bright blue), and cursor
if [ -f "$KITTY_CFG" ]; then
  sed -i -E "s/^(color4[[:space:]]+)#[0-9a-fA-F]{6}/\1${HEX}/" "$KITTY_CFG"
  sed -i -E "s/^(color12[[:space:]]+)#[0-9a-fA-F]{6}/\1${HEX}/" "$KITTY_CFG"
  sed -i -E "s/^(cursor[[:space:]]+)#[0-9a-fA-F]{6}/\1${HEX}/" "$KITTY_CFG"
fi

# rofi: update accent variable
if [ -f "$ROFI_CFG" ]; then
  sed -i -E "s/(accent:[[:space:]]*)#[0-9a-fA-F]{6}(;)/\1${HEX}\2/" "$ROFI_CFG"
fi

# ── 5. Reload i3 ─────────────────────────────────────────────────────────────
if command -v i3-msg >/dev/null 2>&1; then
  i3-msg reload >/dev/null 2>&1 || true
fi

echo "wallpaper-theme: done."
