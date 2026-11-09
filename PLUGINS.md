# Plugins — links, layout, customizations

## Community plugins (GitHub = install source)

| Plugin | ID | Repo |
|---|---|---|
| **OmaStats** | `crmne.omastats` | https://github.com/crmne/omastats |
| **Fathom** | `io.github.mtolhuys.fathom` | https://github.com/mtolhuys/fathom |
| **Omaphones** | `io.github.ncr.omaphones` | https://github.com/ncr/omarchy-headphones |
| **OmaSettings** | `io.github.twiking.omasettings` | https://github.com/twiking/omasettings |
| **Notification Center** | `jankeesvw.notification-center` | https://github.com/jankeesvw/omarchy-notification-center |
| **Time Machine** | `jankeesvw.time-machine` | https://github.com/jankeesvw/omarchy-time-machine |
| **Dynamic Island** | `omarchy-dynamic-island` | https://github.com/Arjun010011/omarchy-dynamic-island |
| **Postcard** | `tahayvr.postcard` | https://github.com/tahayvr/postcard |

Catalog hub: https://plugins.omarchy.org/

### Install one-liners

```bash
omarchy plugin add https://github.com/crmne/omastats.git --enable
omarchy plugin add https://github.com/mtolhuys/fathom.git --enable
omarchy plugin add https://github.com/ncr/omarchy-headphones.git --enable
omarchy plugin add https://github.com/twiking/omasettings.git --enable
omarchy plugin add https://github.com/jankeesvw/omarchy-notification-center.git --enable
omarchy plugin add https://github.com/jankeesvw/omarchy-time-machine.git --enable
omarchy plugin add https://github.com/Arjun010011/omarchy-dynamic-island.git --enable
omarchy plugin add https://github.com/tahayvr/postcard.git --enable
```

### Local-only plugins (copy directories; no public repo)

| Name | Path on source | Bar id |
|---|---|---|
| Wispr Flow panel | `~/.config/omarchy/plugins/wispr-flow-panel/` | `wispr-flow.panel` |
| Voxtral panel | `~/.config/omarchy/plugins/voxtral.panel/` | `voxtral.panel` |
| Muse (muse.ai usage) | `~/.config/omarchy/plugins/muse-agent/` | `muse-agent` |

---

## Global shell (`~/.config/omarchy/shell.json`)

### Idle / lock
```json
"idle": { "lock": 0, "screensaver": 0 }
```
No automatic lock or screensaver. Lock manually via menu if ever wanted.

### Disabled plugins
```json
"disabledPlugins": ["omarchy.notifications", "omarchy.osd"]
```
**Why:** Dynamic Island owns notifications and OSD. Two owners fight.

### Notification Center
- Installed, **`enabled: false`** on purpose.
- Keep off while Island has notifications on.
- If Island is removed later: enable NC **and** restore stock `omarchy.notifications`.

### Dynamic Island (`plugins[]` entry — approximate)

| Setting | Value |
|---|---|
| style | `notch` |
| idle | `pill` |
| idleFace | `ticker` |
| reserveSpace | `true` |
| keybind | `SUPER + ALT + I` |
| notifications / inbox / osd / volume / brightness / charging / media / mic / recording | on |
| textFont | `iA Writer Quattro V` |

### OmaStats — quiet defaults (LEFT strip only)

```json
{
  "id": "crmne.omastats",
  "modules": "cpu,memory",
  "style": "text",
  "cpuStyle": "text",
  "memoryStyle": "text",
  "barLabels": "icon",
  "utilizationColors": "false",
  "showGpuMemory": "false",
  "barGpus": "none"
}
```

Place **left, after workspaces**. Do not dump multi-module graphs on the right on this hardware/layout.

### Bar layout (source machine)

**Left:** `omarchy.menu` → `omarchy.workspaces` → OmaStats (above)  

**Right (order):**  
tray → **wispr-flow.panel** → **voxtral.panel** → Postcard → Time Machine → Omaphones → keyboard-layout → agents → **muse-agent** → bluetooth → network → audio → monitor → power  

**Tray section:** OmaSettings (`io.github.twiking.omasettings`)  

**Center note:** layout may still list `superwhisper.panel`. Superwhisper was **purged** from the source machine — leftover id is harmless if the plugin is missing; clean up when convenient.

### Bar chrome
- `background`: `glassy`
- `position`: `top`

---

## Per-plugin customizations

### Fathom
- Enabled.
- `~/.config/hypr/bindings.lua` loads the plugin’s Hypr file:

```lua
-- fathom: begin
do
  local fathom = os.getenv("HOME") .. "/.config/omarchy/plugins/io.github.mtolhuys.fathom/hypr/fathom.lua"
  local file = io.open(fathom, "r")
  if file then
    file:close()
    pcall(dofile, fathom)
  end
end
-- fathom: end
```

### Postcard binds (`~/.config/hypr/bindings.lua`)

| Chord | Action |
|---|---|
| `SUPER + SHIFT + PRINT` | region capture |
| `SUPER + SHIFT + ALT + PRINT` | last region |
| `SUPER + SHIFT + C` | code card |
| `SUPER + SHIFT + S` | editor toggle |

```lua
o.bind("SUPER + SHIFT + PRINT", "Postcard region", "omarchy-shell shell summon tahayvr.postcard '{\"capture\":\"region\"}'")
o.bind("SUPER + SHIFT + ALT + PRINT", "Postcard last region", "omarchy-shell shell summon tahayvr.postcard '{\"capture\":\"last\"}'")
o.bind("SUPER + SHIFT + C", "Postcard code card", "omarchy-shell shell summon tahayvr.postcard '{\"code\":true}'")
o.bind("SUPER + SHIFT + S", "Postcard editor", "omarchy-shell shell toggle tahayvr.postcard '{}'")
```

### Dynamic Island bind
```lua
o.bind("SUPER + ALT + I", "Toggle island reserved space", "omarchy-shell dynamic-island reserveSpace toggle")
```
(Also driven by `keybind` in shell.json plugin entry.)

### Time Machine
- Config dir: `~/.config/omarchy-time-machine/`
- Source machine destination: local restic repo under `~/Backups/time-machine/` (same-disk = mistake recovery, **not** disaster recovery).
- `excludes.txt` **must** exclude the backup repo path and usually `~/.cache` (plus node_modules etc.) or the first backup locks itself.
- Password file on disk is convenience only — keep the real secret in a password manager off-machine.
- **Never commit** `local-home.key` or restic passwords into git.

### OmaSettings
- Enabled; lives in tray section.
- May write `~/.config/hypr/omasettings.lua` (loaded from `hyprland.lua`).

---

## Omaphones — Moto Buds+ local patch (critical)

Upstream: https://github.com/ncr/omarchy-headphones  

**Local changes are NOT upstream.** `omarchy plugin update` **wipes** them.

### 1. `Model.js` — add Moto backend

- Control UUID: `fc9d9fe0-4899-11ee-be56-0242ac120002`
- `modelNames: ["moto buds+"]`
- `bridge: "moto-bridge"`
- Claim by **name + UUID** so Fast Pair cannot hand the buds to the JBL BLE row.

Diff shape (illustrative — prefer copying the live files from source):

```diff
+var MOTO_CONTROL_UUID = "fc9d9fe0-4899-11ee-be56-0242ac120002"
 ...
+  { name: "moto", bridge: "moto-bridge",
+    modelNames: ["moto buds+"],
+    modelUuids: [MOTO_CONTROL_UUID],
+    args: ["address", "name"] },
   { name: "jbl", bridge: "jbl-bridge",
```

### 2. `moto-bridge`
- Local Python executable in the plugin directory (untracked in upstream git).
- Copy from source:  
  `~/.config/omarchy/plugins/io.github.ncr.omaphones/moto-bridge`

### 3. Capture notes
- `docs/captures/moto-buds-plus.txt` (and related captures) document live PDUs (battery 0x0005, ANC 0x0200/0x0201, etc.).

### Product split
- **Omapods** = AirPods + librepods daemon (different plugin).
- **Omaphones** = other BT headphones (JBL, Sony, **Moto Buds+**, …).
- Moto does **not** go through Omapods.

---

## Muse panel (local)

- Scrapes **muse.ai** (Meta personal agent) usage over **CDP** via `~/.local/bin/muse-usage.cjs` → `~/.cache/omarchy/muse-usage.json`.
- muse.ai has no REST usage API; figures come from the web app.
- CDP target = whichever Chromium-family browser has the debug port (on source: Brave historically on 9222).
- **Not** Muse Code CLI (`mise` install under `~/.local/share/mise/installs/muse/`).

---

## Hotkey collision map (source desk)

| Chord | Owner |
|---|---|
| **Right Option** | **Wispr PTT only** |
| Alt+Space | Contested — Voxtral toggle is parked; do not give to random launchers |
| Super+Space | Omarchy menu |
| Super+Alt+Space | Dock apps |
| Super+Alt+I | Dynamic Island |
| Super+Shift+Print / C / S | Postcard |

Launcher plugins that default to Alt+Space need a **free** bind in `~/.config/hypr/` — never steal Wispr’s Option. Never bind Wispr to Super (app treats L/R Super as one key → fights Hyprland mod).
