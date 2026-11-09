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
3. **[CHECKLIST.md](./CHECKLIST.md)** — install order + smoke tests on the other box  

## Hard rules (do not skip)

- **One dictation engine per physical key.** Right Option = Wispr only on the source machine.
- **Dynamic Island owns notifications + OSD.** Keep stock `omarchy.notifications` and `omarchy.osd` disabled; leave Notification Center off while Island is on.
- **OmaStats stays quiet on the left** (`cpu,memory` text only) — right strip is already dense.
- **`omarchy plugin update` wipes local plugin patches.** Omaphones has a Moto Buds+ patch — stash before updating.
- **Muse (bar) ≠ Muse Code (CLI).** Bar scrapes muse.ai over CDP.

## What is *not* in this repo

Copy these from the source machine if needed (they are local-only / may contain secrets):

| Path | Why |
|---|---|
| `~/.config/omarchy/plugins/wispr-flow-panel/` | Custom panel (no public git) |
| `~/.config/omarchy/plugins/voxtral.panel/` | Custom panel + brand asset |
| `~/.config/omarchy/plugins/muse-agent/` | Custom Muse usage widget |
| `~/.local/bin/muse-usage.cjs` | CDP scraper for muse.ai |
| `~/.config/omarchy/plugins/io.github.ncr.omaphones/Model.js` + `moto-bridge` | Moto patch (diff also documented) |
| `~/.config/omarchy/dictation-voxtral/api_key` | Mistral key |
| `~/.config/omarchy-time-machine/local-home.key` | restic password |
| Wispr `app.asar` patches under `~/.local/opt/wispr-flow/` | Binary bundle patches |

Optional: rsync those directories after cloning this handoff.
