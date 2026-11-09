-- Keep only your personal keybinding overrides here. Add new bindings with
-- o.bind or replace defaults with o.rebind.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding. o.rebind takes the same arguments as o.bind.
-- This example replaces the default file manager with Flea.
-- o.rebind("SUPER + SHIFT + F", "File manager", { launch = "flea" })

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, { panel = "omarchy.emojis" })

-- Postcard (pretty screenshot / code cards)
o.bind("SUPER + SHIFT + PRINT", "Postcard region", "omarchy-shell shell summon tahayvr.postcard '{\"capture\":\"region\"}'")
o.bind("SUPER + SHIFT + ALT + PRINT", "Postcard last region", "omarchy-shell shell summon tahayvr.postcard '{\"capture\":\"last\"}'")
o.bind("SUPER + SHIFT + C", "Postcard code card", "omarchy-shell shell summon tahayvr.postcard '{\"code\":true}'")
o.bind("SUPER + SHIFT + S", "Postcard editor", "omarchy-shell shell toggle tahayvr.postcard '{}'")

-- BEGIN omarchy-dynamic-island
-- Added by the omarchy-dynamic-island plugin and removed with it. Change the key
-- with "keybind" in its entry in ~/.config/omarchy/shell.json.
o.bind("SUPER + ALT + I", "Toggle island reserved space", "omarchy-shell dynamic-island reserveSpace toggle")
-- END omarchy-dynamic-island

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

-- BEGIN voxtral-dictation
-- Omarchy default dictation binds gate on cmd_missing("voxtral") (bare name),
-- which skips registration for omarchy-dictation-voxtral. Bind explicitly.
-- PTT: hold Right Option/Alt. Toggle: Alt+Space. Backup PTT: hold Right Ctrl.
-- DISABLED 2026-11-09: Wispr Flow owns Right Option; two engines on one key is
-- not allowed. Voxtral stays installed and configured (selector + panel) —
-- change the next line back to `do` to restore its keys.
if false then
  local adapter = "omarchy-dictation-voxtral"
  if not o.cmd_missing(adapter) then
    o.bind("ALT + SPACE", "Toggle Voxtral dictation", "omarchy-dictation toggle")
    -- Right Option on Apple MTP keyboards is Alt_R (evdev KEY_RIGHTALT=100).
    o.bind_hold(
      "ALT + Alt_R",
      "Start Voxtral (push-to-talk)",
      "omarchy-dictation start",
      "Stop Voxtral (push-to-talk)",
      "omarchy-dictation stop",
      { ignore_mods = true }
    )
    -- Backup: Right Ctrl hold (always a real distinct key on MacBooks)
    o.bind_hold(
      "CTRL + Control_R",
      "Start Voxtral (Right Ctrl PTT)",
      "omarchy-dictation start",
      "Stop Voxtral (Right Ctrl PTT)",
      "omarchy-dictation stop",
      { ignore_mods = true }
    )
    -- Backup toggle that does not need Option: Super+Shift+Space
    o.bind("SUPER + SHIFT + SPACE", "Toggle Voxtral dictation", "omarchy-dictation toggle")
  end
end
-- END voxtral-dictation
