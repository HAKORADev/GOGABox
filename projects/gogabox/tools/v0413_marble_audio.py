#!/usr/bin/env python3
"""
v0413 MARBLE POPPER AUDIO FORGE
Cuts the scraped gamesnacks audio (the owner's scrape law) + code-modifies:
loudness-normalized, silence-trimmed, converted to ogg, renamed to the mb_*
convention. Music: 4 place themes + the menu bed.
"""
import os, subprocess

TOT = "/home/z/my-project/gogabox/study_locker/gamesnacks/totemia/site/sound/mp3"
ZUM = "/home/z/my-project/gogabox/study_locker/gamesnacks/zumble_ocean/site/assets/audio"
SFX = "/home/z/my-project/gogabox/projects/gogabox/assets/audio/sfx"
MUS = "/home/z/my-project/gogabox/projects/gogabox/assets/audio/music"
os.makedirs(SFX, exist_ok=True)
os.makedirs(MUS, exist_ok=True)

JOBS = [  # (src_path, dst_basename, dst_dir, extras)
    (f"{TOT}/shot01.mp3", "mb_shoot1", SFX, []),
    (f"{TOT}/shot02.mp3", "mb_shoot2", SFX, []),
    (f"{TOT}/ball_inserting.mp3", "mb_insert", SFX, []),
    (f"{TOT}/ball_swap01.mp3", "mb_swap", SFX, []),
    (f"{TOT}/pop.mp3", "mb_pop", SFX, []),
    (f"{TOT}/ball_destroying.mp3", "mb_pop2", SFX, []),
    (f"{TOT}/gap_collapsing.mp3", "mb_gap", SFX, []),
    (f"{TOT}/gap_bonus.mp3", "mb_bonus", SFX, []),
    (f"{TOT}/bomb_explosion.mp3", "mb_bomb", SFX, []),
    (f"{TOT}/lighting.mp3", "mb_lightning", SFX, []),
    (f"{TOT}/lazer.mp3", "mb_rainbow", SFX, []),
    (f"{TOT}/powerup_appearing.mp3", "mb_pow", SFX, []),
    (f"{TOT}/fireball_picking_up.mp3", "mb_powtake", SFX, []),
    (f"{TOT}/coin_bonus.mp3", "mb_coin", SFX, []),
    (f"{TOT}/defeat_heartbeat.mp3", "mb_danger", SFX, []),
    (f"{TOT}/victory.mp3", "mb_win", SFX, []),
    (f"{ZUM}/result_fail.ogg", "mb_lose", SFX, []),
    (f"{ZUM}/not_enough_money.ogg", "mb_deny", SFX, []),
    (f"{TOT}/click.mp3", "mb_click", SFX, []),
    (f"{TOT}/combo1.mp3", "mb_combo1", SFX, []),
    (f"{TOT}/combo2.mp3", "mb_combo2", SFX, []),
    (f"{TOT}/combo3.mp3", "mb_combo3", SFX, []),
    (f"{TOT}/combo4.mp3", "mb_combo4", SFX, []),
    (f"{TOT}/combo5.mp3", "mb_combo5", SFX, []),
    (f"{TOT}/combo6.mp3", "mb_combo6", SFX, []),
    (f"{TOT}/combo7.mp3", "mb_combo7", SFX, []),
    (f"{TOT}/combo8.mp3", "mb_combo8", SFX, []),
    (f"{TOT}/combo9.mp3", "mb_combo9", SFX, []),
    (f"{TOT}/combo10.mp3", "mb_combo10", SFX, []),
    (f"{TOT}/themeA.mp3", "mb_music_a", MUS, ["loop"]),
    (f"{TOT}/themeB.mp3", "mb_music_b", MUS, ["loop"]),
    (f"{TOT}/themeC.mp3", "mb_music_c", MUS, ["loop"]),
    (f"{ZUM}/music_game.ogg", "mb_music_d", MUS, ["loop"]),
    (f"{ZUM}/music_menu.ogg", "mb_music_menu", MUS, ["loop"]),
]

for src, base, dst_dir, _ in JOBS:
    dst = f"{dst_dir}/{base}.ogg"
    r = subprocess.run([
        "ffmpeg", "-y", "-loglevel", "error", "-i", src,
        "-af", "silenceremove=start_periods=1:start_threshold=-46dB,loudnorm=I=-16:TP=-1.5",
        "-ar", "44100", "-c:a", "libvorbis", "-q:a", "4", dst])
    ok = r.returncode == 0 and os.path.getsize(dst) > 500
    print(("OK  " if ok else "FAIL") + " " + dst, flush=True)

print("AUDIO FORGE DONE")
