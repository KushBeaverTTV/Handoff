# Omarchy handoff (MacBook Neo / this desk)

**Private.** For the other Hermes / other machine. Reconstruct the Omarchy plugin + dictation setup without Discord paste limits.

| | |
|---|---|
| Source machine | Omarchy on Hyprland, Arch, **Apple Silicon** MacBook Neo (Asahi dual-boot w/ macOS) |
| GitHub owner | `KushBeaverTTV` |
| Generated | 2026-11-09 |
| Secrets in this repo? | **No** — keys, tokens, restic passwords stay on the machine |

## Read order

1. **[PLUGINS.md](./PLUGINS.md)** — marketplace links, install commands, bar layout, per-plugin customizations  
2. **[DICTATION.md](./DICTATION.md)** — Wispr vs Voxtral vs Voxtype, PTT ownership, both bar panels explained  
3. **[local-plugins/README.md](./local-plugins/README.md)** — **actual panel source** (Wispr / Voxtral / Muse) + install  
4. **[CHECKLIST.md](./CHECKLIST.md)** — install order + smoke tests on the other box  

## What’s in the tree

| Path | Contents |
|---|---|
| `local-plugins/wispr-flow-panel/` | Full Wispr bar plugin (`Panel.qml`, `wispr-status.sh`, manifest) |
| `local-plugins/voxtral.panel/` | Full Voxtral bar plugin + brand assets |
| `local-plugins/muse-agent/` | Full Muse (muse.ai) usage bar plugin |
| `scripts/muse-usage.cjs` | CDP scraper the Muse panel calls |
| `dictation-voxtral/` | Voxtral config, polish prompt, vocabulary (**no api_key**) |
| `hypr/bindings.lua` | Live bindings from source (Postcard, Fathom, Island, Voxtral disabled block) |
| `patches/omaphones-moto/` | Moto Buds+ `Model.js` + `moto-bridge` + diff |
| `shell.json` / `shell-bar-excerpt.json` | Live shell/bar settings from source |

## Hard rules (do not skip)

- **One dictation engine per physical key.** Right Option = Wispr only on the source machine.
- **Dynamic Island owns notifications + OSD.** Keep stock `omarchy.notifications` and `omarchy.osd` disabled; leave Notification Center off while Island is on.
- **OmaStats stays quiet on the left** (`cpu,memory` text only) — right strip is already dense.
- **`omarchy plugin update` wipes local plugin patches.** Omaphones has a Moto Buds+ patch — stash before updating.
- **Muse (bar) ≠ Muse Code (CLI).** Bar scrapes muse.ai over CDP.

## What is *still* not in this repo (secrets / binary patches)

| Path | Why omitted |
|---|---|
| `dictation-voxtral/api_key` | Mistral key — create on the target |
| `~/.config/omarchy-time-machine/local-home.key` | restic password |
| Wispr `app.asar` under `~/.local/opt/wispr-flow/` | Binary bundle patches (pill / centering / close-to-background) — too large / binary; re-apply from notes in DICTATION.md or rsync app tree separately |
| Browser cookies / CDP profile | muse.ai login session |

Local **panel source is in the repo** under `local-plugins/`.
