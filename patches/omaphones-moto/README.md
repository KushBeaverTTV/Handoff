# Omaphones — Moto Buds+ patch

Apply **after** `omarchy plugin add` of upstream Omaphones.

Upstream: https://github.com/ncr/omarchy-headphones  
Plugin dir: `~/.config/omarchy/plugins/io.github.ncr.omaphones/`

```bash
PLUGIN=~/.config/omarchy/plugins/io.github.ncr.omaphones
REPO_PATCH=/path/to/Handoff/patches/omaphones-moto

# Option A — copy full files from this handoff
cp -a "$REPO_PATCH/Model.js" "$PLUGIN/Model.js"
install -m 755 "$REPO_PATCH/moto-bridge" "$PLUGIN/moto-bridge"
mkdir -p "$PLUGIN/docs/captures"
cp -a "$REPO_PATCH/moto-buds-plus.txt" "$PLUGIN/docs/captures/" 2>/dev/null || true

# Option B — apply diff only (if closer to upstream)
# git -C "$PLUGIN" apply "$REPO_PATCH/Model.js.diff"

omarchy restart shell
```

**Warning:** `omarchy plugin update io.github.ncr.omaphones` will wipe this. Stash first.

Contents:
- `Model.js` — patched with `moto` backend + `MOTO_CONTROL_UUID`
- `Model.js.diff` — git diff vs upstream at patch time
- `moto-bridge` — Python bridge binary used by the backend
- `moto-buds-plus.txt` — live capture notes (PDU / battery / ANC)
