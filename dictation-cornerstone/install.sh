#!/usr/bin/env bash
# Installs Cornerstone dictation from this repo onto this machine: the command,
# its settings, and the bar panel. Touches only files in your home folder.
#
# Speech engine: this installer selects the Mistral cloud engine, because the
# local speech models (about 12 GB, built for the desktop PC's graphics card)
# are not in this repo. An existing settings folder is kept, not overwritten.
#
# It does NOT make Cornerstone the active dictation key and does NOT store an
# API key. Both are the two commands printed at the end.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(dirname "$HERE")"
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy"
DEST="$CONF/dictation-cornerstone"
BIN="$HOME/.local/bin"

for c in jq curl pw-record wtype; do
  command -v "$c" >/dev/null || echo "Note: '$c' is not installed; dictation needs it."
done

mkdir -p "$BIN" "$CONF/plugins"
install -m 755 "$HERE/bin/omarchy-dictation-cornerstone" "$BIN/omarchy-dictation-cornerstone"
ln -sfn "$BIN/omarchy-dictation-cornerstone" "$BIN/cornerstone"

if [[ -e $DEST/config.json ]]; then
  echo "Kept your existing settings in $DEST"
else
  mkdir -p "$DEST"
  cp -r "$HERE/config/." "$DEST/"
  tmp=$(mktemp)
  jq '.stt_engine = "mistral" | del(.mic_target)' "$DEST/config.json" >"$tmp" && mv "$tmp" "$DEST/config.json"
  chmod 600 "$DEST/config.json"
fi

rm -rf "$CONF/plugins/cornerstone.panel"
cp -r "$REPO/local-plugins/cornerstone.panel" "$CONF/plugins/"
chmod +x "$CONF/plugins/cornerstone.panel/cornerstone-status.sh"

cat <<MSG
Installed. Two steps are left for you:

1. Save your Mistral key (it is typed hidden and stays on this machine):
     read -rs k && printf '%s\n' "\$k" > "$DEST/api_key" && chmod 600 "$DEST/api_key"; unset k

2. Make Cornerstone the active dictation engine and show its bar panel:
     echo cornerstone > "$CONF/defaults/dictation"
     omarchy plugin enable cornerstone.panel
     omarchy restart shell
MSG
