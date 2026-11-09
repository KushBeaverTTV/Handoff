# Wispr Flow — full setup (not just the bar panel)

**This is the actual dictation app.** The Omarchy bar widget (`local-plugins/wispr-flow-panel/`) is only a status light + Hub buttons. Without this install, the panel is a dead badge.

Source machine daily driver: unofficial Linux port **1.6.1337-1.0.5**, **Right Option (VK 165) PTT**, systemd user service, patched `app.asar`, bar panel, start/stop sounds.

---

## 0. What you are installing

| Piece | Role |
|---|---|
| **App** | Electron + Linux helper (injects text into focused app) |
| **udev rule** | `/dev/uinput` write + `/dev/input/event*` read (PTT + paste) |
| **systemd `wispr-flow.service`** | Starts app with graphical session env (not a bare TTY) |
| **systemd `wispr-flow-sounds.service`** | Start/stop WAV cues (port’s built-in sounds don’t fire reliably) |
| **Bar panel** | `wispr-flow.panel` from this repo’s `local-plugins/` |
| **app.asar patches** | Kill Flow Bar pill, fix Hub centering, close-Hub-doesn’t-quit |
| **Prefs** | PTT = 165, hide Flow Bar, polish on, style map |

Official product site: https://wisprflow.ai (account/login)  
Unofficial Linux packaging: https://github.com/wispr-flow-linux/wispr-flow-linux  

**Do not** install AUR `wispr-flow` packages on Apple Silicon — they are **x86_64**. Use the **aarch64 AppImage** (or arm64 deb/rpm) from the port’s GitHub Releases.

---

## 1. Download + extract the app (aarch64)

Pinned release (matches source desk):

```text
https://github.com/wispr-flow-linux/wispr-flow-linux/releases/download/v1.0.5%2Bwispr1.6.1337/wispr-flow-1.6.1337-1.0.5-aarch64.AppImage
```

x86_64 box? Same tag, `…-x86_64.AppImage`.

```bash
set -euo pipefail
VER=1.6.1337-1.0.5
ARCH=$(uname -m)   # aarch64 or x86_64
URL="https://github.com/wispr-flow-linux/wispr-flow-linux/releases/download/v1.0.5%2Bwispr1.6.1337/wispr-flow-${VER}-${ARCH}.AppImage"

mkdir -p ~/.local/opt ~/Downloads
cd ~/Downloads
curl -L --fail -o "wispr-flow-${VER}-${ARCH}.AppImage" "$URL"
chmod +x "wispr-flow-${VER}-${ARCH}.AppImage"

# Extract AppImage payload into a stable directory (same layout as source)
rm -rf ~/.local/opt/wispr-flow
mkdir -p ~/.local/opt/wispr-flow
cd ~/.local/opt/wispr-flow
# AppImage extract
~/Downloads/wispr-flow-${VER}-${ARCH}.AppImage --appimage-extract
# squashfs-root → contents
shopt -s dotglob
mv squashfs-root/* .
rmdir squashfs-root 2>/dev/null || rm -rf squashfs-root

# Launcher on PATH
mkdir -p ~/.local/bin
ln -sfn ~/.local/opt/wispr-flow/AppRun ~/.local/bin/wispr-flow

# Desktop entry + icon
mkdir -p ~/.local/share/applications ~/.local/share/icons/hicolor/256x256/apps
cp -f "$(dirname "$0")/desktop/wispr-flow.desktop" ~/.local/share/applications/ 2>/dev/null \
  || cat > ~/.local/share/applications/wispr-flow.desktop <<'EOF'
[Desktop Entry]
Name=Wispr Flow
Comment=Voice Dictation
Exec=wispr-flow %U
TryExec=wispr-flow
Icon=wispr-flow
Terminal=false
Type=Application
Categories=Utility;AudioVideo;Audio;
StartupWMClass=wispr-flow
MimeType=x-scheme-handler/wispr-flow;
Keywords=voice;dictation;speech;transcription;
EOF
cp -f ~/.local/opt/wispr-flow/ai.wisprflow.WisprFlow.png \
  ~/.local/share/icons/hicolor/256x256/apps/wispr-flow.png 2>/dev/null || true
update-desktop-database ~/.local/share/applications 2>/dev/null || true

wispr-flow --help 2>&1 | head -5 || true
test -x ~/.local/opt/wispr-flow/usr/lib/wispr-flow/wispr-flow
echo "App tree OK: ~/.local/opt/wispr-flow"
```

Or run the installer in this folder:

```bash
bash wispr-flow/install.sh
```

---

## 2. udev — PTT and paste will not work without this

AppImage **cannot** install the rule itself. From a **graphical** session:

```bash
# Preferred: app helper (pkexec GUI prompt)
wispr-flow --install-udev-rules

# Or copy the rule from this repo (needs root once)
sudo cp wispr-flow/udev/70-wispr-flow-uinput.rules /usr/lib/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger

# Fallback if uaccess is weird on the distro:
sudo usermod -aG input "$USER"
# then log out/in
```

Verify:

```bash
wispr-flow --doctor
# Need PASS on uinput write + input event read
ls -l /dev/uinput
```

Rule contents (also in `udev/70-wispr-flow-uinput.rules`):

- `KERNEL=="uinput"` → `TAG+=uaccess`, group `input`, mode 0660  
- `SUBSYSTEM=="input", KERNEL=="event*"` → same  

Without this: PTT silent, paste/injection fails.

---

## 3. Start it the only supported way — user systemd

**Never** launch `wispr-flow` from an agent/SSH/TTY with stripped env. You get `No display detected (TTY session)` or Ozone crashes.

```bash
# From this Handoff clone:
install -m 644 wispr-flow/systemd/wispr-flow.service ~/.config/systemd/user/
install -m 644 wispr-flow/systemd/wispr-flow-sounds.service ~/.config/systemd/user/

# Sounds daemon + WAVs
install -m 755 wispr-flow/bin/wispr-flow-sound-daemon ~/.local/bin/
mkdir -p ~/.local/share/sounds/wispr-flow
install -m 644 wispr-flow/sounds/*.wav ~/.local/share/sounds/wispr-flow/

systemctl --user daemon-reload
systemctl --user enable --now wispr-flow.service
systemctl --user enable --now wispr-flow-sounds.service

systemctl --user status wispr-flow.service --no-pager
pgrep -af 'wispr-flow/usr/lib/wispr-flow/wispr-flow'
```

Restart later:

```bash
systemctl --user restart wispr-flow.service
# Do NOT pkill -f with a pattern that matches your own shell wrapper
```

Confirm graphical env is on the user manager:

```bash
systemctl --user show-environment | rg 'WAYLAND|DISPLAY'
```

---

## 4. Sign in

1. Open Hub: `xdg-open wispr-flow://open` or click the bar panel later.  
2. Sign in with the user’s Wispr account (student plan on source — cloud STT).  
3. Grant mic access when prompted (PipeWire/portal).

---

## 5. Push-to-talk = Right Option only (code 165)

The in-app shortcut recorder **rejects bare modifiers**. Write prefs directly.

Config file: `~/.config/Wispr Flow/config.json`  
(path has a **space** — quote it)

### VK codes this port uses (Windows-style)

| Code | Key |
|---|---|
| **165** | **Right Option / Alt_R** ← **PTT** |
| 164 | Left Alt |
| 91 / 92 | Super L/R — **NEVER bind PTT here** (app treats L/R Super as one key → fires on Hyprland mod) |
| 160 | Left Shift |
| 27 | Escape |
| 162 | Ctrl |

### Minimum edit after first launch creates the file

Stop the app first so it doesn’t overwrite mid-edit:

```bash
systemctl --user stop wispr-flow.service
python3 <<'PY'
import json
from pathlib import Path
p = Path.home() / "config/Wispr Flow/config.json".replace("config/", ".config/")
# fixed:
p = Path.home() / ".config" / "Wispr Flow" / "config.json"
if not p.exists():
    raise SystemExit(f"missing {p} — start the app once, sign in, stop service, re-run")
d = json.loads(p.read_text())
user = d.setdefault("prefs", {}).setdefault("user", {})
user["shortcuts"] = {
    "27": "dismiss",
    "165": "ptt",  # Right Option
    # keep or merge other chords the user wants
}
user["hideFlowBarPermanently"] = True
user["polishEnabled"] = True
# Linux AX context is broken → almost all text gets type "other"
# stock maps other→formal (corporate). Prefer casual:
styles = user.setdefault("personalizationStyles", {})
styles["other"] = "casual"
styles.setdefault("personal", "casual")
styles.setdefault("work", "excited")
styles.setdefault("email", "formal")
p.write_text(json.dumps(d, indent=2))
print("wrote", p)
PY
systemctl --user start wispr-flow.service
```

Recommended snippet also in `wispr-flow/prefs/recommended-user-prefs.json`.

**Hard rule with Omarchy:** only **one** engine may own Right Option. On the source desk Voxtral Hypr binds are `if false then` so Wispr alone has Option. See `DICTATION.md` / `hypr/bindings.lua`.

---

## 6. app.asar patches (source desk UX)

Live bundle: `~/.local/opt/wispr-flow/usr/lib/wispr-flow/resources/app.asar`  
Backup before patch: `app.asar.bak-pre-patch`

Patches applied on source (must be **re-done after every AppImage upgrade** — updater is inert, upgrades are manual swaps):

1. **Flow Bar pill suppressed** on three code paths (idle show, dictation-start re-show, status-window factory), gated on `prefs.user.hideFlowBarPermanently`. Bar widget is the only status UI.  
2. **Hub self-centering disabled** (`center:!0` → `center:!1` style anchor) — app mixed logical/physical pixels at 2× and landed off-screen.  
3. **`window-all-closed` → `e.preventDefault()`** — closing the Hub must **not** quit Electron; app stays headless; panel “Open Hub” / `wispr-flow://open` brings it back.  
4. Stale-key recovery made synchronous (phantom shortcut matches).

**Practical options for the other machine:**

- **A (fastest parity):** scp/rsync the **already patched** `app.asar` (+ keep `app.asar.bak-pre-patch`) from the source MacBook after stock extract. Files are ~163MB — not stored in this git repo.  
  ```bash
  # on source
  ls -la ~/.local/opt/wispr-flow/usr/lib/wispr-flow/resources/app.asar*
  # scp to target same path, then restart wispr-flow.service
  ```
- **B:** run stock until patches are re-derived; set `hideFlowBarPermanently` anyway; accept pill/centering/quit-on-close until patched.

There is no durable upstream patch series — anchors shift when Wispr bumps the Windows build the port repacks.

---

## 7. Omarchy bar panel (the status light)

From Handoff repo root:

```bash
rsync -a local-plugins/wispr-flow-panel/ ~/.config/omarchy/plugins/wispr-flow-panel/
omarchy plugin enable wispr-flow.panel
# place on right strip if needed — see shell-bar-excerpt.json
omarchy restart shell
```

Panel behavior (already in the plugin):

- `wispr-status.sh` → `off|idle|recording|processing`  
- Process match: `/wispr-flow/usr/lib/wispr-flow/wispr-flow`  
- State from `~/.cache/wispr-flow/launcher.log` lines `updateDictationStatus:` (**not** pactl — worklet doesn’t show as source-output)  
- Actions: Hub deeplink, hands-free start/stop, start/quit app, restart  
- IPC: `omarchy-shell wispr-flow status|open|dictate|power|restart`

---

## 8. Sounds

Port’s in-app start/stop sounds often don’t fire. Source uses:

- `~/.local/bin/wispr-flow-sound-daemon` (in this repo under `wispr-flow/bin/`)  
- WAVs in `~/.local/share/sounds/wispr-flow/`  
- `wispr-flow-sounds.service` tails the launcher log:  
  - `listening` → start.wav  
  - `dismissed` / `idle` after recording → stop.wav  

Needs `paplay` (PipeWire/Pulse).

---

## 9. Hyprland notes

Source `hyprland.lua` comment: **no special window rules** for Wispr. Hub is a normal window. Pill is removed; bar widget is status.

Do **not** give Omarchy/Voxtral `Alt_R` hold while Wispr owns 165.

---

## 10. Smoke test (definition of done)

```bash
systemctl --user is-active wispr-flow wispr-flow-sounds
pgrep -af 'wispr-flow/usr/lib/wispr-flow/wispr-flow'
wispr-flow --doctor          # uinput + input PASS
test -r /dev/uinput && test -w /dev/uinput

# hold Right Option in a text field → should dictate
# launcher log should show updateDictationStatus: listening
tail -f ~/.cache/wispr-flow/launcher.log | rg updateDictationStatus

# bar panel should go red/recording while listening
# close Hub → process still alive
pgrep -af wispr-flow
xdg-open wispr-flow://open   # Hub returns
```

Fail matrix:

| Symptom | Likely cause |
|---|---|
| `No display detected` | Started from TTY/agent — use systemd |
| PTT does nothing | udev / not in `input` / wrong shortcut code |
| Hears you, doesn’t type | uinput / helper / focus |
| Panel always `off` | service down or process path mismatch |
| Panel `idle` but never recording | log path / status lines; check launcher.log |
| Hub vanishes and kills dictation | missing window-all-closed asar patch |
| Hub opens off-screen | missing centering patch; move with Super+mouse |
| Corporate tone always | `personalizationStyles.other` still `formal` |
| Option also triggers Voxtral | Hypr binds not disabled — see DICTATION.md |

---

## 11. Coexistence

| Engine | On source |
|---|---|
| Wispr | **Daily PTT (165)** |
| Voxtral | Configured; Hypr block `if false then` |
| Voxtype | Available backend only |
| Superwhisper | Purged |

One physical key → one engine. Always.

---

## 12. Files in this repo under `wispr-flow/`

```text
RELEASE.txt                         # download URLs + version pin
install.sh                          # download, extract, link, units, udev helper, sounds, panel hint
systemd/wispr-flow.service
systemd/wispr-flow-sounds.service
udev/70-wispr-flow-uinput.rules
bin/wispr-flow-sound-daemon
sounds/dictation-start.wav
sounds/dictation-stop.wav
desktop/wispr-flow.desktop
prefs/recommended-user-prefs.json
prefs/config-redacted-example.json  # shape only; secrets stripped
hypr/hyprland-wispr-comment.lua
```

Panel source: `../local-plugins/wispr-flow-panel/`  
Dictation coexistence: `../DICTATION.md`  
Bar placement: `../shell-bar-excerpt.json`
