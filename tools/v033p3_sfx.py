#!/usr/bin/env python3
"""v0.3.3 PATCH 3 - MATCHER audio.
1) The owner's Match_3_Template zip sounds become the DEFAULT matcher voice
   (the owner: "it has ... amazing SFXs that i guess using it as the default
   will be cooler" + "the game music except peace uses GOGABox main menu music
   while you could have used the uploaded SFXs in that zip").
2) New numpy synth sounds for the three NEW modes (jelly / ice crash / drop
   down) + the new specials (bomb, sweepers, color wipe) + the spider grace.
"""
import os, shutil, subprocess, wave, struct, math, random

ZIP = "/home/z/my-project/asset_trials/m3t/sounds"
SFX = "/home/z/my-project/repo/GOGABox/projects/gogabox/assets/audio/sfx"
MUS = "/home/z/my-project/repo/GOGABox/projects/gogabox/assets/audio/music"

# ---------------------------------------------------------------- zip imports
COPIES = [
    # (zip file, dest folder, dest name)
    ("snd_music_game/snd_music_game.mp3", MUS, "matcher_game.mp3"),
    ("snd_match_small/snd_match_small.wav", SFX, "m_match_soft.wav"),
    ("snd_match_big/snd_match_big.wav", SFX, "m_match_big.wav"),
    ("snd_donut_pop/snd_donut_pop.wav", SFX, "m_pop_candy.wav"),
    ("snd_donut_land/snd_donut_land.wav", SFX, "m_land.wav"),          # upgrade
    ("snd_invalid_match/snd_invalid_match.wav", SFX, "m_invalid.wav"),
    ("snd_piece_swap/snd_piece_swap.wav", SFX, "m_swap.wav"),          # upgrade
    ("snd_special_token_bomb/snd_special_token_bomb.wav", SFX, "m_tok_bomb.wav"),
    ("snd_special_token_whoosh/snd_special_token_whoosh.wav", SFX, "m_tok_whoosh.wav"),
    ("snd_powerup_selection/snd_powerup_selection.wav", SFX, "m_arm.wav"),      # upgrade
    ("snd_powerup_sprinkles/snd_powerup_sprinkles.wav", SFX, "m_shuffle.wav"),  # upgrade
    ("snd_powerup_icing/snd_powerup_icing.wav", SFX, "m_freeze.wav"),           # upgrade
    ("snd_powerup_coffee_pour/snd_powerup_coffee_pour.wav", SFX, "m_jelly_spread.wav"),
    ("snd_powerup_coffee_drink/snd_powerup_coffee_drink.wav", SFX, "m_gulp.wav"),  # upgrade
    ("snd_star_award_in_game/snd_star_award_in_game.wav", SFX, "m_special.wav"),   # upgrade
    ("snd_star_award_complete/snd_star_award_complete.wav", SFX, "m_goal.wav"),    # upgrade
    ("snd_game_win/snd_game_win.mp3", SFX, "m_win_fanfare.mp3"),
    ("snd_game_lose/snd_game_lose.mp3", SFX, "m_lose_org.mp3"),
    ("snd_ui_click/snd_ui_click.wav", SFX, "m_ui.wav"),
    ("snd_ui_close/snd_ui_close.wav", SFX, "m_ui_close.wav"),
]
for src, dst_dir, dst in COPIES:
    s = os.path.join(ZIP, src)
    d = os.path.join(dst_dir, dst)
    os.makedirs(dst_dir, exist_ok=True)
    shutil.copyfile(s, d)
    print("zip ->", dst)

# ---------------------------------------------------------------- synth helpers
SR = 44100

def write_wav(name, data):
    data = [max(-1.0, min(1.0, x)) for x in data]
    p = os.path.join(SFX, name)
    with wave.open(p, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(x * 32000)) for x in data))
    print("synth ->", name)

def env(i, n, a=0.01, r=0.3):
    t = i / n
    at = max(0.001, a)
    e = 1.0
    if t < at:
        e = t / at
    if t > 1.0 - r:
        e = min(e, max(0.0, (1.0 - t) / r))
    return e

def tone(f, dur, vol=0.5, wave_fn="sine", a=0.01, r=0.3):
    n = int(SR * dur)
    out = []
    ph = 0.0
    for i in range(n):
        ph += 2 * math.pi * f / SR
        if wave_fn == "sine":
            v = math.sin(ph)
        elif wave_fn == "tri":
            v = 2 / math.pi * math.asin(math.sin(ph))
        elif wave_fn == "saw":
            v = 2 * ((ph / (2 * math.pi)) % 1.0) - 1
        else:
            v = random.uniform(-1, 1)
        out.append(v * vol * env(i, n, a, r))
    return out

def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out

def cat(*tracks):
    out = []
    for t in tracks:
        out.extend(t)
    return out

def sweep(f0, f1, dur, vol=0.5, wave_fn="sine", a=0.01, r=0.25):
    n = int(SR * dur)
    out = []
    ph = 0.0
    for i in range(n):
        f = f0 * (f1 / f0) ** (i / n)
        ph += 2 * math.pi * f / SR
        v = math.sin(ph) if wave_fn == "sine" else (2 * ((ph / (2 * math.pi)) % 1.0) - 1)
        out.append(v * vol * env(i, n, a, r))
    return out

def noise(dur, vol=0.4, a=0.005, r=0.2, lp=0.0):
    n = int(SR * dur)
    out = []
    prev = 0.0
    for i in range(n):
        v = random.uniform(-1, 1)
        if lp > 0:
            v = prev + lp * (v - prev)
            prev = v
        out.append(v * vol * env(i, n, a, r))
    return out

def delay(track, sec):
    return [0.0] * int(SR * sec) + track

# ---------------------------------------------------------------- new mode sfx
random.seed(20260905)

# JELLY: squelchy pop (the jelly dissolves) - pitch-down wobble + wet click
m = mix(sweep(520, 130, 0.30, 0.5), delay(noise(0.10, 0.25, lp=0.25), 0.02))
write_wav("m_jelly_pop.wav", m)
# ICE CRASH: layer crack - sharp noise burst + high ping
m = mix(noise(0.14, 0.5, lp=0.5), delay(tone(1900, 0.22, 0.28, "tri", r=0.5), 0.03),
        delay(sweep(900, 500, 0.18, 0.2), 0.02))
write_wav("m_icehit.wav", m)
# ICE CRASH: full break - crash + falling shards
m = mix(noise(0.3, 0.6, lp=0.35),
        cat(tone(1400, 0.1, 0.2, "tri"), tone(1000, 0.1, 0.18, "tri"), tone(700, 0.16, 0.16, "tri")),
        sweep(300, 90, 0.35, 0.3))
write_wav("m_icebreak.wav", m)
# ROCK clank (matches bounce off the rock layer)
m = mix(tone(180, 0.16, 0.6, "tri", r=0.5), tone(290, 0.1, 0.3, "sine", r=0.4), noise(0.05, 0.3, lp=0.6))
write_wav("m_rockhit.wav", m)
# DROP item lands a step (soft wood knock)
m = mix(tone(340, 0.09, 0.5, "tri", r=0.4), delay(tone(240, 0.08, 0.35, "sine"), 0.045))
write_wav("m_itemdrop.wav", m)
# DROP item collected (bright double chime)
m = cat(tone(880, 0.09, 0.4, "sine", r=0.2), delay(tone(1318, 0.22, 0.4, "sine", r=0.5), 0.07))
write_wav("m_itemget.wav", m)
# LINE SWEEPER zip (row/col) - fast rise whoosh
m = mix(sweep(300, 2400, 0.22, 0.42, "saw", r=0.3), noise(0.18, 0.18, lp=0.4))
write_wav("m_sweep.wav", m)
# COLOR WIPE - rising shimmer (the bottom-up color remover)
parts = []
for k in range(8):
    parts.append(delay(tone(600 * (2 ** (k / 8.0)), 0.08, 0.16, "sine", r=0.4), k * 0.035))
m = mix(*parts)
write_wav("m_colorwipe.wav", m)
# SPIDER GRACE sting (the warning when a butterfly touches the top)
m = mix(tone(196, 0.5, 0.4, "tri", r=0.4), delay(tone(185, 0.45, 0.3, "tri", r=0.5), 0.12))
write_wav("m_grace.wav", m)
# CHALLENGE life lost - soft sad blip pair
m = cat(tone(392, 0.14, 0.4), delay(tone(311, 0.26, 0.4), 0.13))
write_wav("m_lifelost.wav", m)
# LEVEL clear (jelly / ice crash levels)
m = cat(tone(523, 0.12, 0.4), delay(tone(659, 0.12, 0.4), 0.1), delay(tone(784, 0.3, 0.42, r=0.5), 0.2))
write_wav("m_levelup.wav", m)
# JELLY spread squish (darker squelch)
m = mix(sweep(300, 90, 0.26, 0.5), delay(noise(0.12, 0.2, lp=0.2), 0.05), tone(70, 0.2, 0.3, "sine", r=0.5))
write_wav("m_jelly_spread2.wav", m)
# ICE CRASH spread - cold creeping shimmer
m = mix(sweep(1400, 500, 0.3, 0.16, "sine", r=0.4), noise(0.22, 0.12, lp=0.3))
write_wav("m_icespread.wav", m)
# ITEM spawn at the top (little pop + sparkle)
m = cat(tone(660, 0.08, 0.3, "tri"), delay(tone(990, 0.14, 0.3, "sine", r=0.4), 0.06))
write_wav("m_itemspawn.wav", m)
print("PHASE A audio done")
