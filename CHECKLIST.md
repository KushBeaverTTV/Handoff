# Checklist — bring another Omarchy box up to this desk

Work top to bottom. After plugin/bar edits: `omarchy restart shell`.

## 0. Wispr Flow app (daily dictation) — DO THIS, not “enable a panel”
- [ ] Read **[WISPR-FLOW.md](./WISPR-FLOW.md)** end to end
- [ ] `bash wispr-flow/install.sh` (downloads aarch64/x86_64 AppImage from wispr-flow-linux releases)
- [ ] `wispr-flow --install-udev-rules` then `wispr-flow --doctor` (uinput + input PASS)
- [ ] `systemctl --user enable --now wispr-flow wispr-flow-sounds`
- [ ] Sign in: `xdg-open wispr-flow://open`
- [ ] Set PTT **Right Option = VK 165** in `~/.config/Wispr Flow/config.json` (see §5)
- [ ] `hideFlowBarPermanently: true`; prefer `personalizationStyles.other: casual`
- [ ] Ensure **no** Voxtral/Omarchy bind on Alt_R (DICTATION.md / hypr/bindings.lua `if false then`)
- [ ] Optional: copy patched `app.asar` from source for pill/centering/close-to-background (§6)
- [ ] Bar panel: `local-plugins/wispr-flow-panel` (install.sh does this if Omarchy present)
- [ ] Smoke: hold Right Option → text types; panel shows recording; close Hub → process stays up

## 1. Community plugins
- [ ] Install the eight git plugins from [PLUGINS.md](./PLUGINS.md)
- [ ] Enable Dynamic Island before relying on notifications
- [ ] Disable stock `omarchy.notifications` and `omarchy.osd` in shell / plugin list
- [ ] Leave Notification Center **off** while Island owns notifs
- [ ] OmaStats: left after workspaces; modules `cpu,memory`; text; no utilization rainbow
- [ ] Fathom: ensure `bindings.lua` loads plugin `hypr/fathom.lua`
- [ ] Postcard: add the four Super+Shift binds
- [ ] Island: Super+Alt+I reserve toggle present

## 2. Omaphones / audio
- [ ] If user has **AirPods** → consider Omapods (separate stack), not only Omaphones
- [ ] If user has **Moto Buds / Buds+** → copy `Model.js` patch + `moto-bridge` from source **after** plugin add
- [ ] Confirm `omarchy plugin update` will not run on Omaphones without stashing local files

## 3. Local panels (from this repo — not “ask the other machine”)
- [ ] Follow [local-plugins/README.md](./local-plugins/README.md)
- [ ] rsync `local-plugins/wispr-flow-panel` → `~/.config/omarchy/plugins/wispr-flow-panel/`
- [ ] rsync `local-plugins/voxtral.panel` → `~/.config/omarchy/plugins/voxtral.panel/`
- [ ] rsync `local-plugins/muse-agent` → `~/.config/omarchy/plugins/muse-agent/`
- [ ] `install -m 755 scripts/muse-usage.cjs ~/.local/bin/muse-usage.cjs`
- [ ] `omarchy plugin enable` each of `wispr-flow.panel`, `voxtral.panel`, `muse-agent`
- [ ] Merge bar placement from `shell-bar-excerpt.json` if needed
- [ ] Remove stale `superwhisper.panel` bar entry if present
- [ ] Omaphones Moto: [patches/omaphones-moto/README.md](./patches/omaphones-moto/README.md)
- [ ] Voxtral non-secret config: copy `dictation-voxtral/*` then add `api_key` yourself

## 4. Dictation — pick ONE PTT owner
### If Wispr (matches source daily driver)
- [ ] Install Wispr port + udev rule + user systemd unit
- [ ] PTT = Right Option (code 165) only
- [ ] Apply or restore app.asar patches (pill / centering / close-to-background) if same UX wanted
- [ ] Voxtral: install adapter + key + config, keep panel
- [ ] Voxtral binds: `if false then` in bindings.lua
- [ ] No bare `~/.local/bin/voxtral` symlink (blocks stock Omarchy dictation binds) **or** accept and verify zero dual binds
- [ ] `hyprctl binds` shows no competing Voxtral PTT on Alt_R

### If Voxtral instead
- [ ] Stop Wispr PTT / quit Wispr or unbind Option
- [ ] `omarchy-dictation-use voxtral`
- [ ] Symlink `voxtral` → `omarchy-dictation-voxtral`
- [ ] Flip bindings block to `do`; reload Hypr
- [ ] Smoke: start/stop writes `~/.local/state/omarchy-dictation-voxtral/status`

### If Voxtype
- [ ] `omarchy-dictation-use voxtype` and install models via omarchy voxtype helpers
- [ ] Still one engine on Option — unbind the others

## 5. Time Machine
- [ ] `config create` / destinations / key / init / install timer (plugin CLI)
- [ ] Excludes include backup repo path + cache
- [ ] Password stored off-machine; don’t commit key files

## 6. Smoke
- [ ] Island shows a test notification; stock OSD not double-firing
- [ ] OmaStats readable, left side, not colliding
- [ ] Postcard region chord works
- [ ] Wispr panel: idle → recording on PTT (if Wispr owner)
- [ ] Voxtral panel: not stuck on `nokey` if key present; last text updates after a test dictation (if Voxtral used)
- [ ] Moto buds (if any): battery/ANC under Omaphones
- [ ] Muse % updates only if CDP browser + muse.ai session available

## 7. Done looks like
- Island handles notifs/OSD; no double bell  
- OmaStats quiet cpu/mem on the left  
- Exactly one engine owns Right Option  
- Both dictation panels may show status; only one records  
- Omaphones Moto patch intact if relevant  
- No secrets accidentally pushed to git  
