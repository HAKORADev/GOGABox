#!/usr/bin/env python3
"""
v0.4.0-17 THE SLIM AUDIO LAW - every WAV source in assets/audio becomes OGG.

WHY: the WAV sources are raw PCM (115 MB on disk). QOA import already
squeezes them ~5:1 inside the pck, but OGG Vorbis q6 lands ~3x smaller than
the QOA samples AND plays identically for game music/sfx. This slims the
Windows exe, BOTH APKs, and the repo itself. The Jukebox already prefers
.ogg when resolving bare sfx names (game/core/audio.gd _resolve), and it
force-loops ogg music streams at runtime, so behavior is unchanged.

WHAT:
  1. every assets/audio/**/*.wav -> same path .ogg (ffmpeg libvorbis q6)
  2. ffprobe duration cross-check (tolerance 150 ms) - nothing ships deaf
  3. the .wav + .wav.import files are deleted (the ogg import is generated
     by `godot --import` afterwards)
  4. every res://assets/audio/*.wav string reference in game/ -> .ogg
     (the dev/ + tools/ sheets keep their dated history untouched)

Re-run safe: files already converted are skipped.
"""
import subprocess, sys, os, glob

ROOT = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.join(ROOT, "..", "projects", "gogabox")
AUDIO = os.path.join(PROJ, "assets", "audio")
Q = "6"          # libvorbis quality 6 ~= 192 kbps stereo - transparent for the box
TOL = 0.15       # seconds of duration drift the law allows


def sh(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def duration(path):
    r = sh(["ffprobe", "-v", "error", "-show_entries", "format=duration",
            "-of", "default=noprint_wrappers=1:nokey=1", path])
    try:
        return float(r.stdout.strip())
    except ValueError:
        return -1.0


def main() -> int:
    if not os.path.isdir(AUDIO):
        print("no assets/audio dir - nothing to do")
        return 1
    wavs = sorted(glob.glob(os.path.join(AUDIO, "**", "*.wav"), recursive=True))
    if not wavs:
        print("no wav sources left - the slim audio law already holds")
    converted = skipped = failed = 0
    before_sum = after_sum = 0
    for wav in wavs:
        ogg = wav[:-4] + ".ogg"
        before_sum += os.path.getsize(wav)
        if os.path.exists(ogg):
            skipped += 1
            after_sum += os.path.getsize(ogg)
            continue
        r = sh(["ffmpeg", "-y", "-loglevel", "error", "-i", wav,
                "-c:a", "libvorbis", "-q:a", Q, ogg])
        if r.returncode != 0 or not os.path.exists(ogg) \
                or os.path.getsize(ogg) == 0:
            print("FAIL convert:", wav, r.stderr[-200:])
            failed += 1
            if os.path.exists(ogg):
                os.remove(ogg)
            continue
        d0, d1 = duration(wav), duration(ogg)
        if d0 < 0 or d1 < 0 or abs(d0 - d1) > TOL:
            print("FAIL duration: %s (%.2fs -> %.2fs)" % (wav, d0, d1))
            failed += 1
            os.remove(ogg)
            continue
        after_sum += os.path.getsize(ogg)
        os.remove(wav)
        imp = wav + ".import"
        if os.path.exists(imp):
            os.remove(imp)
        converted += 1
    print("converted %d, skipped(already) %d, failed %d" %
          (converted, skipped, failed))
    print("audio sources: %.1f MB -> %.1f MB (ogg on disk)" %
          (before_sum / 1048576.0, after_sum / 1048576.0))
    if failed:
        return 1

    # ---- the code references: res://assets/audio/...wav -> .ogg ----
    game = os.path.join(PROJ, "game")
    refs = 0
    for dirpath, _dirs, files in os.walk(game):
        for fn in files:
            if not fn.endswith(".gd"):
                continue
            p = os.path.join(dirpath, fn)
            src = open(p, encoding="utf-8").read()
            out = src.replace(".wav\"", ".ogg\"")
            if out != src:
                refs += src.count(".wav\"") - out.count(".wav\"")
                open(p, "w", encoding="utf-8").write(out)
    print("patched %d .wav -> .ogg string refs in game/" % refs)
    return 0


if __name__ == "__main__":
    sys.exit(main())
