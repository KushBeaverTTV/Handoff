#!/usr/bin/env bash
# Installs the Cyberpunk 2077 Omarchy theme from this repo onto this machine:
# the theme folder, the yellow folder-icon set, and the hook that makes
# Files/GTK windows black and yellow. Touches only files in your home folder.
# Does not switch the theme; run the command printed at the end for that.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy"
ICONS="${XDG_DATA_HOME:-$HOME/.local/share}/icons"

mkdir -p "$CONF/themes/cyberpunk-2077" "$CONF/hooks/theme-set.d" "$ICONS"
cp -r "$HERE/theme/." "$CONF/themes/cyberpunk-2077/"
rm -rf "$ICONS/Yaru-cyberpunk"
cp -r "$HERE/icons/Yaru-cyberpunk" "$ICONS/"
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -q "$ICONS/Yaru-cyberpunk" 2>/dev/null || true
install -m 755 "$HERE/hooks/20-gtk-accent" "$CONF/hooks/theme-set.d/20-gtk-accent"

echo "Installed. To switch to it:   omarchy theme set cyberpunk-2077"
echo "Boot splash (asks for your password):   omarchy plymouth set by theme cyberpunk-2077"
