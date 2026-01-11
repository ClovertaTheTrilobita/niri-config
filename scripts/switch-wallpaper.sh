#!/bin/bash

# This Script will change wallpaper to the selected image.
# It will copy the selected image to `$HOME/.config/niri/wallpapers/` and make a blurred version.
# Then set wallpaper and background.

set -euo pipefail
img="${1:-}"

if [ -z "$img" ]; then
  echo "Missing Params, usage: switch-wallpaper.sh <img>"
  exit 1
fi

if [ ! -f "$img" ]; then
  echo "File $img not found. Please check your path."
  exit 1
fi

mkdir -p "$HOME/.config/niri/wallpapers"

echo "Copying $img to $HOME/.config/niri/wallpapers/"
cp -- "$img" "$HOME/.config/niri/wallpapers/"

name=$(basename -- "$img")
wallp="$HOME/.config/niri/wallpapers/$name"

base=${wallp%.*}
ext=${wallp##*.}

echo "Making a blurred version of the image..."
magick "$wallp" -blur 0x18 \
  "${base}-blur.${ext}"

NIRI_CONFIG_PATH="$HOME/.config/niri"
config="$NIRI_CONFIG_PATH/src/auto-start.kdl"
img_path="${base}-blur.${ext}"

[ -f "$config" ] || {
  echo "config not found: $config" >&2
  exit 1
}
[ -w "$config" ] || {
  echo "config not writable: $config" >&2
  exit 1
}

echo "Updating Niri configuration..."
if ! grep -Eq '^[[:space:]]*spawn-sh-at-startup[[:space:]]+"swaybg[[:space:]]+-i[[:space:]]+[^"]+[[:space:]]+-m[[:space:]]+fill"[[:space:]]*$' "$config"; then
  echo "没找到需要替换的 swaybg -m fill 行，未修改。" >&2
  exit 1
fi

escaped_img_path=$(printf '%s' "$img_path" | sed 's/[&\\|]/\\&/g')

sed -i.bak -E \
  "s|^([[:space:]]*spawn-sh-at-startup[[:space:]]+\"swaybg[[:space:]]+-i[[:space:]]+)[^\"]+([[:space:]]+-m[[:space:]]+fill\"[[:space:]]*)$|\1${escaped_img_path}\2|g" \
  "$config"

echo "Wallpaper upated🥳"

swww img "$wallp"
pkill -x swaybg 2>/dev/null || true

nohup swaybg -i "$img_path" -m fill >/dev/null 2>&1 &
