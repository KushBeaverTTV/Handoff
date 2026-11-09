Voxtral dictation (Mistral)
===========================
1. Open https://console.mistral.ai/ (or Studio / Vibe → API keys)
2. Create a key that can call Speech-to-Text / Voxtral
3. Paste it alone into:  ~/.config/omarchy/dictation-voxtral/api_key
   (one line, no quotes)
4. Then run:  omarchy-dictation-use voxtral

Hold Right Alt to dictate (same Omarchy dictation keys).
Alt+Space toggles dictation.
Logs: ~/.local/state/omarchy-dictation-voxtral/last.log

NOTE: Hermes reported the previous MISTRAL_API_KEY expired 2026-11-07.
You need a fresh Vibe/Studio key for Voxtral to work.
