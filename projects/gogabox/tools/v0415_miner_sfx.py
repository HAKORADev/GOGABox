#!/usr/bin/env python3
"""
v0415 GOLD MINER AUDIO FORGE
Cuts the scraped goldminertom sounds (the owner's scrape law) + code-modifies:
loudness-normalized, converted to ogg, renamed to the gm_* convention.
DIFFERENT SFX FOR THE THINGS (the owner's law): gold S/M/L + rock S/M/L +
bomb + coin each wear their own voice (plus runtime pitch shifts).
"""
import os, subprocess

SRC = "/home/z/my-project/study_locker/gamesnacks/goldminertom/media"
SFX = "/home/z/my-project/gogabox/projects/gogabox/assets/audio/sfx"
MUS = "/home/z/my-project/gogabox/projects/gogabox/assets/audio/music"
os.makedirs(SFX, exist_ok=True)
os.makedirs(MUS, exist_ok=True)

JOBS = [  # (src, dst, dst_dir, pitch_hz, extras)
    ("start.ogg",    "gm_start",    SFX, None, []),
    ("puff.ogg",     "gm_launch",   SFX, None, []),        # the throw
    ("machine.ogg",  "gm_reel",     SFX, None, ["loop"]),   # the winch (looped longer)
    ("pop.ogg",      "gm_grab",     SFX, None, []),        # claw closes
    ("point.ogg",    "gm_gold_s",   SFX, None, []),        # small gold
    ("good.ogg",     "gm_gold_m",   SFX, None, []),        # medium gold
    ("great.ogg",    "gm_gold_l",   SFX, None, []),        # large gold
    ("rattle.ogg",   "gm_rock_s",   SFX, None, []),        # small rock
    ("counter.ogg",  "gm_rock_m",   SFX, None, []),        # medium rock
    ("bag.ogg",      "gm_rock_l",   SFX, None, []),        # large rock
    ("getbomb.ogg",  "gm_bomb_hit", SFX, None, []),        # the bomb touch
    ("explode.ogg",  "gm_blast",    SFX, None, []),        # the blast
    ("getpower.ogg", "gm_coin",     SFX, None, []),        # the GOGACoin
    ("success.ogg",  "gm_clear",    SFX, None, []),        # ground cleared
    ("fail.ogg",     "gm_over",     SFX, None, []),        # the run ends
    ("low.ogg",      "gm_empty",    SFX, None, []),        # claw came back bare
    ("pop.ogg",      "gm_click",    SFX, 220.0, []),       # UI (pitch-shifted)
    ("purchase.ogg", "gm_buy",      SFX, None, []),        # the shop
    ("music.ogg",    "gm_music",    MUS, None, []),         # the bed (Godot loops it)
]

def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit(f"FAIL {cmd}: {r.stderr}")

for src, dst, ddir, pitch, extras in JOBS:
    s = f"{SRC}/{src}"
    d = f"{ddir}/{dst}.ogg"
    filters = ["loudnorm=I=-16:TP=-1.5:LRA=11"]
    if pitch:
        filters.append(f"asetrate=44100*{44100/(44100+pitch):.6f},aresample=44100")
    cmd = ["ffmpeg", "-y"]
    if "loop" in extras:
        cmd += ["-stream_loop", "7"]
    cmd += ["-i", s, "-af", ",".join(filters),
            "-ar", "44100", "-ac", "1", "-b:a", "96k", d]
    run(cmd)
    print(f"{dst}.ogg  <- {src}" + (f"  pitch {pitch}" if pitch else ""))

print("AUDIO FORGE DONE")
