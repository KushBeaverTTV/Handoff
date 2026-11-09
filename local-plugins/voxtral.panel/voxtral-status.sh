#!/usr/bin/env bash
# Voxtral bar-widget state probe. Prints exactly one line:
#   idle | recording | processing | error | nokey
set -u
status_file="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-dictation-voxtral/status"
pid_file="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-dictation-voxtral/record.pid"
key_file="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/dictation-voxtral/api_key"

if [[ ! -s $key_file ]] && [[ -z ${MISTRAL_API_KEY:-} ]]; then
  echo nokey
  exit 0
fi

if [[ -f $pid_file ]]; then
  pid=$(cat "$pid_file" 2>/dev/null || true)
  if [[ -n ${pid:-} ]] && kill -0 "$pid" 2>/dev/null; then
    echo recording
    exit 0
  fi
fi

if [[ -f $status_file ]]; then
  s=$(tr -d ' \t\r\n' <"$status_file")
  case "$s" in
    idle|recording|processing|error|nokey) echo "$s" ;;
    *) echo idle ;;
  esac
  exit 0
fi

echo idle
