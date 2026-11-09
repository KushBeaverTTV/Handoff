#!/usr/bin/env bash
# Wispr Flow bar-widget state probe. Prints exactly one line:
#   off        no Wispr Flow process
#   recording  dictation listening (mic live)
#   processing  transcription running
#   idle       running, nothing active
#
# The app captures audio through its own recorder worklet, which never shows
# up as a pactl source-output — the app's own status transitions in its
# launcher log are the only reliable signal.
set -u

bin_pattern="/wispr-flow/usr/lib/wispr-flow/wispr-flow"

if ! pgrep -f "$bin_pattern" >/dev/null 2>&1; then
  echo off
  exit 0
fi

log="${HOME}/.cache/wispr-flow/launcher.log"
status=$(grep -a "updateDictationStatus:" "$log" 2>/dev/null | tail -1 | sed -E 's/.*updateDictationStatus: ([a-z]+).*/\1/')

case "$status" in
  listening)  echo recording ;;
  processing) echo processing ;;
  starting)   echo processing ;;
  stopping)   echo processing ;;
  *)          echo idle ;;
esac
