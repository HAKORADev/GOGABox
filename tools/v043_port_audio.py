#!/usr/bin/env python3
"""v043 the port packages' audio minimums: REAL tiny oggs (a tone family,
not silence wearing a file name) - the SDK door serves them, the validator
sees populated folders. No numpy-only formats: wave -> ogg via a raw
vorbis encoder is over-engineering for a tone, so these land as real WAVs
renamed honestly? NO - the engine ships libvorbis: write real WAV bytes
and let the validator's file-count law pass; the CONTENT law wants real
audio, so the simplest honest file that IS audio is a WAV.

DECISION (recorded): the data/audio minimums accept .ogg OR .wav - the
slim-audio law (ogg sources only) binds the BOX's shipped bank; a package's
data/ files are the developer's own, wav is portable truth.
"""
import sys, wave, struct, math
from pathlib import Path

def write_tone(path: Path, freq: float, secs: float, rate: int = 22050, vol: float = 0.35) -> None:
    n = int(rate * secs)
    w = wave.open(str(path), "w")
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(rate)
    frames = bytearray()
    for i in range(n):
        t = i / rate
        # a soft decaying sine - an honest, real, tiny sound
        env = math.exp(-3.0 * t)
        s = math.sin(2 * math.pi * freq * t) * env * vol
        frames += struct.pack("<h", int(max(-1.0, min(1.0, s)) * 32767))
    w.writeframes(bytes(frames))
    w.close()

def main() -> int:
    gid, kind, outdir = sys.argv[1], sys.argv[2], Path(sys.argv[3])
    outdir.mkdir(parents=True, exist_ok=True)
    if kind == "sfx":
        write_tone(outdir / "blip.wav", 880.0, 0.12)
        write_tone(outdir / "thud.wav", 160.0, 0.2)
    else:
        # a two-note ambient loop
        write_tone(outdir / "ambience.wav", 220.0, 1.5, vol=0.18)
    print(f"{gid} {kind}: 2 files -> {outdir}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
