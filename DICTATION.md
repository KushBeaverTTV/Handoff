# Dictation — Wispr, Voxtral, Voxtype, panels

## Architecture (source machine)

| Engine | What it is | Role on source |
|---|---|---|
| **Wispr Flow** | Unofficial Linux aarch64 port of Wispr | **Daily driver PTT** (Right Option) |
| **Voxtral** | Omarchy adapter → Mistral STT API (+ optional polish) | Installed + configured; **Hypr binds disabled** so it doesn’t steal Option |
| **Voxtype** | Omarchy local/on-device STT (`voxtype-bin`) | Available via selector; not daily driver |
| Superwhisper | — | **Purged** |

Selector file: `~/.config/omarchy/defaults/dictation`  
On source this currently says `voxtral`. That names the Omarchy backend adapter — it does **not** mean Voxtral owns the keyboard. **Key ownership is separate** (Wispr on Right Option; Voxtral block is `if false then`).

```bash
omarchy-dictation-use voxtral|superwhisper|voxtype
```

**Hard rule:** never two dictation engines on the same physical key.

---

## Wispr Flow (app)

### Paths / service
| Item | Path / unit |
|---|---|
| App tree | `~/.local/opt/wispr-flow` |
| Launcher | `~/.local/bin/wispr-flow` |
| systemd | `~/.config/systemd/user/wispr-flow.service` (WantedBy graphical-session) |
| Sounds | `wispr-flow-sounds.service` |
| Prefs | `~/.config/Wispr Flow/config.json` |

### PTT
- **Right Option only** — shortcut code **165** (`VK_RMENU`) in `prefs.user.shortcuts`.
- Do **not** bind Super for Wispr (left/right Super treated as one key → collides with Hyprland mod).
- Agent terminals often lack a display: launching `wispr-flow` from a stripped TTY fails with “No display detected”. Use the **user systemd service** / graphical session.

### udev
- `/usr/lib/udev/rules.d/70-wispr-flow-uinput.rules`  
- Install via app: `wispr-flow --install-udev-rules` (pkexec).  
- Grants `/dev/uinput` write and `/dev/input/event*` read via uaccess (needed for injection + PTT).

### app.asar patches (source)

Backup: `~/.local/opt/wispr-flow/usr/lib/wispr-flow/resources/app.asar.bak-pre-patch`

1. **Flow Bar pill removed** — idle show, dictation-start re-show, and status-window factory short-circuit when hide-permanently is set. **The Omarchy bar widget is the only status indicator.**
2. **Hub self-centering removed** — Electron math mixed logical vs physical pixels at 2× scale and landed off-screen. Hyprland centers floating windows normally.
3. **Close Hub ≠ quit** — `window-all-closed` handler keeps the app running headless. User preference: close window to background, don’t fully quit. “Open Hub” from the panel reopens it.

### Hyprland
- Comment block in `~/.config/hypr/hyprland.lua` documents: no special window rules; Hub is a normal tiled/floating app; pill removed; bar widget is status.

---

## Wispr Flow **panel** (`wispr-flow.panel`)

**Path:** `~/.config/omarchy/plugins/wispr-flow-panel/`  
**Local-only** — not on plugins.omarchy.org.

| File | Role |
|---|---|
| `manifest.json` | id `wispr-flow.panel`, kind bar-widget, default section `right` |
| `wispr-status.sh` | prints exactly one line: `off` \| `idle` \| `recording` \| `processing` |
| `Panel.qml` | bar mark + popover actions + IPC |

### Status probe (`wispr-status.sh`)
1. If no process matching `/wispr-flow/usr/lib/wispr-flow/wispr-flow` → `off`.
2. Else parse last `updateDictationStatus:` from `~/.cache/wispr-flow/launcher.log`.
3. Map: `listening` → `recording`; `processing|starting|stopping` → `processing`; else `idle`.

**Why not pactl?** Wispr’s recorder worklet often does **not** show up as a PipeWire source-output. Launcher log is the reliable signal.

### UI / behavior
- Five-bar Wispr mark.
- Colors: recording **`#E11414`**, processing **`#2B8DD4`** (reads as “live” on this theme; stock urgent is too muted).
- Poll ~2s.
- Actions: start/quit app, open Hub (`wispr-flow://open`), hands-free dictate via deeplinks, restart (quit + delayed start).
- IPC target `wispr-flow`: `open | toggle | status | dictate | power | restart`  
  Example: `omarchy-shell wispr-flow status`
- Flow Bar toggle intentionally **not** exposed (pill patched out of the app).

---

## Voxtral backend (Omarchy)

### Layout
```
~/.local/bin/omarchy-dictation-voxtral
~/.local/bin/voxtral                    # symlink to above WHEN binds should register
~/.config/omarchy/defaults/dictation    # selected backend name
~/.config/omarchy/dictation-voxtral/
  api_key                 # one line, chmod 600 — NEVER commit
  config.json
  vocabulary.txt
  polish-system.txt
  README.txt
~/.local/state/omarchy-dictation-voxtral/
  status | last_text | last_raw | last.log | record.pid
```

### `config.json` (source values)
```json
{
  "stt_model": "voxtral-mini-transcribe-3",
  "language": "en",
  "polish": true,
  "polish_model": "mistral-small-latest",
  "style": "natural"
}
```
Styles available: `natural` | `chat` | `email` | `code`.  
Avoid broken `…-latest` aliases for the STT model id; use the pinned `voxtral-mini-transcribe-3` (or current known-good).

### Pipeline
1. `omarchy-dictation start|stop|toggle` → `omarchy-dictation-$backend`
2. Record 16 kHz mono WAV (`pw-record` / ffmpeg)
3. `POST https://api.mistral.ai/v1/audio/transcriptions`
4. If polish on: chat completion with polish system prompt + vocabulary + style
5. Type with `wtype`; clipboard fallback `wl-copy`
6. Write status / last_text for the bar

```bash
omarchy-dictation-voxtral polish-on|polish-off
omarchy-dictation-voxtral style natural|chat|email|code
omarchy-dictation-voxtral config
```

### Polish voice rules (non-negotiable on this user)
- Fix ASR mistakes and light punctuation only.
- **Do not** formalize African American English / casual register into corporate SAE.
- Keep dialect, slang, cadence when that is what was said.
- Prefer vocabulary list spellings for tech/names/voice terms.
- Full text lives in `polish-system.txt` and `vocabulary.txt` on the source machine — copy those files; don’t invent a colder prompt.

### Hypr binds — currently DISABLED on source

In `~/.config/hypr/bindings.lua`:

```lua
-- BEGIN voxtral-dictation
-- DISABLED 2026-11-09: Wispr Flow owns Right Option; two engines on one key
-- is not allowed. Voxtral stays installed (selector + panel).
-- Change `if false then` back to `do` to restore keys.
if false then
  local adapter = "omarchy-dictation-voxtral"
  if not o.cmd_missing(adapter) then
    o.bind("ALT + SPACE", "Toggle Voxtral dictation", "omarchy-dictation toggle")
    o.bind_hold(
      "ALT + Alt_R",
      "Start Voxtral (push-to-talk)",
      "omarchy-dictation start",
      "Stop Voxtral (push-to-talk)",
      "omarchy-dictation stop",
      { ignore_mods = true }
    )
    o.bind_hold(
      "CTRL + Control_R",
      "Start Voxtral (Right Ctrl PTT)",
      "omarchy-dictation start",
      "Stop Voxtral (Right Ctrl PTT)",
      "omarchy-dictation stop",
      { ignore_mods = true }
    )
    o.bind("SUPER + SHIFT + SPACE", "Toggle Voxtral dictation", "omarchy-dictation toggle")
  end
end
-- END voxtral-dictation
```

### Enabling Voxtral keys later
1. Unbind / stop Wispr PTT on Right Option (or the user accepts losing Wispr on that key).
2. `ln -sfn ~/.local/bin/omarchy-dictation-voxtral ~/.local/bin/voxtral`
3. Flip `if false then` → `do` in bindings.lua.
4. `hyprctl reload` (set `HYPRLAND_INSTANCE_SIGNATURE` from `$XDG_RUNTIME_DIR/hypr/` if calling from agent TTY).
5. Confirm: `hyprctl binds | rg -i 'dictation|Voxtral|Alt_R|Control_R'`

### Disabling Omarchy stock dictation binds (when Wispr owns the key)
Omarchy’s built-in `bindings/dictation.lua` gates on bare backend name on PATH.  
**Remove** the `voxtral` symlink so stock binds never register, **and** keep the user block at `if false then`. Both gates matter.

---

## Voxtral **panel** (`voxtral.panel`)

**Path:** `~/.config/omarchy/plugins/voxtral.panel/`  
**Local-only.**

| File | Role |
|---|---|
| `manifest.json` | id `voxtral.panel` |
| `assets/voxtral.png` | official Mistral/Voxtral mark |
| `voxtral-status.sh` | `idle` \| `recording` \| `processing` \| `error` \| `nokey` |
| `Panel.qml` | status UI + actions |

### Status probe
1. No key file and no `MISTRAL_API_KEY` → `nokey`
2. Live `record.pid` process → `recording`
3. Else read `~/.local/state/omarchy-dictation-voxtral/status`

### UI / behavior
- Brand colors: record orange `#FA500F`, process blue `#0082E6`, error red.
- Poll 250ms while live, ~900ms idle.
- Actions call `omarchy-dictation start|stop|toggle`.
- Panel: polish on/off, cycle style, copy last transcript, open log / key file / config.
- Shows last transcript from `last_text`.
- IPC target `voxtral`.

**Both Wispr and Voxtral panels stay on the bar** while engines are compared. Panels do not decide mic ownership — **selector + Hypr binds** do.

---

## Voxtype (what it is)

- Package: `omarchy/voxtype-bin` — local push-to-talk voice-to-text for Linux.
- Omarchy wrapper: `omarchy-dictation-voxtype` → `voxtype record start|stop|toggle`.
- Helpers: `omarchy-voxtype-config`, `omarchy-voxtype-model`, install/remove scripts.
- On-device models (CPU/GPU), not Mistral cloud.
- Marketplace plugins named “Voxtype Enhance / OSD / tray” are **shell UIs on top of Voxtype**, not Voxtype itself.
- On source: available backend, **not** the daily PTT owner.

---

## Quick “who has the mic?” debug

```bash
cat ~/.config/omarchy/defaults/dictation
systemctl --user is-active wispr-flow.service
pgrep -af wispr-flow | head
hyprctl binds | rg -i 'dictation|Voxtral|Wispr|Alt_R|voxtype'
# Wispr PTT code in prefs:
# ~/.config/Wispr Flow/config.json → prefs.user.shortcuts (165 = Right Option)
ls -l ~/.local/bin/voxtral 2>/dev/null
rg -n 'if false then|voxtral-dictation' ~/.config/hypr/bindings.lua
```
