# Cyberpunk 2077 theme for Omarchy

Yellow (`#fcee0a`) borders and highlights on near-black, white text, sharp
corners. Built on the desktop PC on 10 Nov 2026.

| Path | What it is |
|---|---|
| `theme/` | The theme itself: `colors.toml`, nine official CD Projekt wallpapers, preview and boot-logo images, `gtk3.css` / `gtk4.css` |
| `icons/Yaru-cyberpunk/` | Folder icons recoloured to the game's yellow (copy of Yaru-yellow) |
| `hooks/20-gtk-accent` | Runs on every theme change: makes Files and other GTK windows black/yellow for this theme, puts stock back for any other |
| `install.sh` | Copies the three pieces into place |

## Install on another Omarchy machine

```bash
git clone https://github.com/KushBeaverTTV/Handoff.git ~/Projects/Handoff   # or: git pull
bash ~/Projects/Handoff/themes/cyberpunk-2077/install.sh
omarchy theme set cyberpunk-2077
```

Optional boot splash (needs your password): `omarchy plymouth set by theme cyberpunk-2077`

Wallpapers are 3840x2160 except `4-logotype.jpg` (2560x1600). Steam, Spotify
and other apps that draw their own interface are not recoloured.
