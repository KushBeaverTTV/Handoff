# Local plugins — install on the other machine

These are **first-party custom panels** from the source desk. Not on plugins.omarchy.org.

```text
local-plugins/
  wispr-flow-panel/     → bar id wispr-flow.panel
  voxtral.panel/        → bar id voxtral.panel
  muse-agent/           → bar id muse-agent
scripts/
  muse-usage.cjs        → ~/.local/bin/muse-usage.cjs (required by muse-agent)
```

## Install

```bash
# from a clone of this repo
REPO="$(pwd)"   # or path to Handoff clone

rsync -a "$REPO/local-plugins/wispr-flow-panel/" \
  ~/.config/omarchy/plugins/wispr-flow-panel/
rsync -a "$REPO/local-plugins/voxtral.panel/" \
  ~/.config/omarchy/plugins/voxtral.panel/
rsync -a "$REPO/local-plugins/muse-agent/" \
  ~/.config/omarchy/plugins/muse-agent/

install -m 755 "$REPO/scripts/muse-usage.cjs" ~/.local/bin/muse-usage.cjs

# enable (ids must match manifest.json)
omarchy plugin enable wispr-flow.panel
omarchy plugin enable voxtral.panel
omarchy plugin enable muse-agent

# place on bar if not already in shell.json — see shell-bar-excerpt.json
omarchy restart shell
```

Or merge `shell-bar-excerpt.json` / `shell.json` bar layout from this repo into `~/.config/omarchy/shell.json` (right strip already lists these three on the source machine).

## What’s in each panel

| Plugin | Files | Does |
|---|---|---|
| **wispr-flow-panel** | `Panel.qml`, `wispr-status.sh`, `manifest.json` | Live Wispr state (off/idle/recording/processing) from process + launcher log; Hub / dictate / power via `wispr-flow://` deeplinks |
| **voxtral.panel** | `Panel.qml`, `voxtral-status.sh`, `assets/*`, `manifest.json` | Live Voxtral state from status files; start/stop via `omarchy-dictation`; polish/style controls; brand mark |
| **muse-agent** | `Panel.qml`, `manifest.json` | muse.ai usage % via CDP scraper (`muse-usage.cjs` → `~/.cache/omarchy/muse-usage.json`); not Muse Code CLI |

## Also in this repo (related)

| Path | Purpose |
|---|---|
| `dictation-voxtral/` | config, polish prompt, vocabulary (**no api_key**) |
| `hypr/bindings.lua` | Postcard, Fathom, Island, Voxtral block (`if false then`) |
| `patches/omaphones-moto/` | full `Model.js`, `moto-bridge`, diff, capture notes |
| `shell.json` / `shell-bar-excerpt.json` | live bar + plugin settings from source |

## Secrets you still add yourself

```bash
# Voxtral
printf '%s\n' "$MISTRAL_KEY" > ~/.config/omarchy/dictation-voxtral/api_key
chmod 600 ~/.config/omarchy/dictation-voxtral/api_key
cp -a dictation-voxtral/* ~/.config/omarchy/dictation-voxtral/

# Muse scraper needs a browser with CDP (Brave/Chromium remote debugging) and a muse.ai session
```
