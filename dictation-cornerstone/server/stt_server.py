#!/usr/bin/env python3
"""Cornerstone local STT service.

Keeps Whisper large-v3-turbo (faster-whisper / CTranslate2, CPU int8) loaded
in RAM and serves transcription on 127.0.0.1 for the Cornerstone dictation
backend. Stdlib HTTP only; one request at a time (dictation is serial).

  GET  /health     -> {"status": "ok", "model": ..., "vocab_terms": N}
  POST /transcribe -> body: WAV bytes (16 kHz mono s16le as recorded by
                      pw-record). Response: {"text", "audio_s", "elapsed_s"}

Vocabulary: the hotwords list is built from the dictation vocabulary file
(non-comment lines, comma-separated terms) and refreshed when the file's
mtime changes, so dictionary edits take effect without a restart.
"""
import argparse
import io
import json
import os
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

LOCK = threading.Lock()
MODEL = None
MODEL_NAME = ""
VOCAB_PATH = ""
_vocab_cache = {"mtime": None, "hotwords": "", "count": 0}


def load_vocab():
    try:
        mtime = os.path.getmtime(VOCAB_PATH)
    except OSError:
        return "", 0
    if _vocab_cache["mtime"] == mtime:
        return _vocab_cache["hotwords"], _vocab_cache["count"]
    terms = []
    try:
        with open(VOCAB_PATH, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                for term in line.split(","):
                    term = term.strip()
                    if term:
                        terms.append(term)
    except OSError:
        return "", 0
    hotwords = ", ".join(terms)
    # Keep the prompt-side bias bounded; first terms are the proper nouns.
    if len(hotwords) > 1000:
        hotwords = hotwords[:1000].rsplit(",", 1)[0]
    _vocab_cache.update(mtime=mtime, hotwords=hotwords, count=len(terms))
    return hotwords, len(terms)


def transcribe_wav(wav_bytes):
    import wave

    with wave.open(io.BytesIO(wav_bytes)) as w:
        frames = w.readframes(w.getnframes())
        rate = w.getframerate()
        width = w.getsampwidth()
        chans = w.getnchannels()
    if width != 2:
        raise ValueError(f"expected 16-bit PCM wav, got sample width {width}")
    import numpy as np

    audio = np.frombuffer(frames, dtype=np.int16).astype(np.float32) / 32768.0
    if chans > 1:
        audio = audio.reshape(-1, chans).mean(axis=1)
    audio_s = len(audio) / float(rate)
    hotwords, _ = load_vocab()
    t0 = time.time()
    segments, _info = MODEL.transcribe(
        audio,
        language="en",
        beam_size=5,
        vad_filter=True,
        vad_parameters={"min_silence_duration_ms": 500},
        condition_on_previous_text=False,
        hotwords=hotwords or None,
        without_timestamps=True,
    )
    text = "".join(seg.text for seg in segments).strip()
    return text, audio_s, time.time() - t0


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        sys.stderr.write("stt: %s\n" % (fmt % args))

    def _json(self, code, obj):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/health":
            _, count = load_vocab()
            self._json(200, {"status": "ok", "model": MODEL_NAME, "vocab_terms": count})
        else:
            self._json(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/transcribe":
            self._json(404, {"error": "not found"})
            return
        length = int(self.headers.get("Content-Length") or 0)
        if length <= 44:
            self._json(400, {"error": "empty audio"})
            return
        wav = self.rfile.read(length)
        with LOCK:
            try:
                text, audio_s, elapsed = transcribe_wav(wav)
            except Exception as e:  # keep the service alive on bad input
                self._json(500, {"error": f"{type(e).__name__}: {e}"})
                return
        self._json(200, {"text": text, "audio_s": round(audio_s, 2), "elapsed_s": round(elapsed, 3)})


def main():
    global MODEL, MODEL_NAME, VOCAB_PATH
    ap = argparse.ArgumentParser()
    ap.add_argument("--model-dir", required=True)
    ap.add_argument("--vocab-file", required=True)
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--threads", type=int, default=24)
    args = ap.parse_args()

    VOCAB_PATH = args.vocab_file
    MODEL_NAME = os.path.basename(args.model_dir.rstrip("/"))
    from faster_whisper import WhisperModel

    t0 = time.time()
    MODEL = WhisperModel(
        args.model_dir,
        device="cpu",
        compute_type="int8",
        cpu_threads=args.threads,
        num_workers=1,
    )
    print(f"stt: model {MODEL_NAME} loaded in {time.time() - t0:.1f}s, vocab={load_vocab()[1]} terms", flush=True)
    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    print(f"stt: listening on 127.0.0.1:{args.port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
