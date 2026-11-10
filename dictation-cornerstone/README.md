# Cornerstone dictation

Press the dictation key, talk, and the words are typed wherever the cursor is.
Snapshot of the desktop PC's setup, 10 Nov 2026. **No API key in this repo.**

| Path | What it is |
|---|---|
| `bin/omarchy-dictation-cornerstone` | The command (also runs as `cornerstone`) |
| `config/` | Settings, tidy-up prompt, vocabulary, word replacements, start/stop sounds, logos |
| `../local-plugins/cornerstone.panel/` | The bar panel |
| `systemd/` | The three speech services as they run on the desktop PC |
| `server/` | Source for the local speech servers (`stt_server.py`, `qwen-server/server.c`, build script) |
| `install.sh` | Installs the command, settings and panel |

## Install on another Omarchy machine

```bash
bash ~/Projects/Handoff/dictation-cornerstone/install.sh
```

Then follow the two steps it prints (save the Mistral key, switch the
dictation engine to Cornerstone).

## Local speech vs cloud speech

On the desktop PC, speech is turned into text on the machine itself
(Qwen3-ASR and Whisper on the RX 7900 XT). Those models are about 12 GB, were
built for that graphics card, and are not in this repo. The service files in
`systemd/` point at `/mnt/storage/files/dictation` on the desktop PC and will
not run elsewhere as they are.

`install.sh` therefore selects the Mistral cloud engine
(`omarchy-dictation-cornerstone engine mistral`), which needs only a Mistral
API key. This has not been tested on the MacBook.

`config.json` here still holds the desktop's microphone (`mic_target`);
`install.sh` removes that line so the other machine uses its default mic.
