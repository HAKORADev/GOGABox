#!/usr/bin/env python3
# ============================================================================
# v034 COSMIC SPUD - the audio pipeline.
# Curates the CC0 hunt (download/cs_assets/raw/audio) into the box's audio
# dirs with cs_ prefixes, converts music to clean ogg loops via ffmpeg, and
# numpy-synthesizes the gaps. Every file is ffprobe-verified at the end.
#   SFX  -> projects/gogabox/assets/audio/sfx/cs_*.ogg|wav
#   MUS  -> projects/gogabox/assets/audio/music/cs_*.ogg
# All CC0 (provenance: download/cs_assets/MANIFEST.md + assets.manifest.json)
# ============================================================================
import os, shutil, subprocess, json
import numpy as np

RAW = "/home/z/my-project/download/cs_assets/raw/audio"
SFX = "/home/z/my-project/repo/GOGABox/projects/gogabox/assets/audio/sfx"
MUS = "/home/z/my-project/repo/GOGABox/projects/gogabox/assets/audio/music"
os.makedirs(SFX, exist_ok=True)
os.makedirs(MUS, exist_ok=True)

SCI = f"{RAW}/kenney_sci-fi-sounds/Audio"
IMP = f"{RAW}/kenney_impact-sounds/Audio"
UI  = f"{RAW}/kenney_ui-audio/Audio"
DIG = f"{RAW}/kenney_digital-audio/Audio"
RPG = f"{RAW}/kenney_rpg-audio/Audio"
GUN = f"{RAW}/sfx/impacts_gun/Impacts"
MUSDIR = f"{RAW}/music"

report = []

def ff(path):
    r = subprocess.run(["ffprobe", "-v", "quiet", "-show_entries",
                        "format=duration", "-of", "csv=p=0", path],
                       capture_output=True, text=True)
    try:
        return float(r.stdout.strip())
    except Exception:
        return -1.0

def cpy(src, dst):
    shutil.copy(src, dst)
    report.append((os.path.basename(dst), os.path.basename(src), ff(dst)))
    print("sfx", os.path.basename(dst), "%.2fs" % ff(dst))

def conv(src, dst, br="128k", trim=None, fade=None):
    cmd = ["ffmpeg", "-y", "-v", "error", "-i", src]
    if trim:
        cmd += ["-ss", str(trim[0]), "-t", str(trim[1] - trim[0])]
    cmd += ["-c:a", "libvorbis", "-b:a", br, "-ar", "44100", "-ac", "2"]
    if fade:
        cmd += ["-af", fade]
    cmd += [dst]
    subprocess.run(cmd, check=True)
    report.append((os.path.basename(dst), os.path.basename(src), ff(dst)))
    print("mus", os.path.basename(dst), "%.2fs" % ff(dst))

# ---------------------------------------------------------------- SFX map
# per-family shots, impacts, crits, kills, pickups, ui, world
cpy(f"{GUN}/Gunshot 1.wav",  f"{SFX}/cs_shot_smg.wav")
cpy(f"{GUN}/Gunshot 2.wav",  f"{SFX}/cs_shot_smg2.wav")
cpy(f"{GUN}/Shotgun 1.wav",  f"{SFX}/cs_shot_shotgun.wav")
cpy(f"{GUN}/Gunshot 6.wav",  f"{SFX}/cs_shot_rifle.wav")
cpy(f"{SCI}/laserSmall_000.ogg", f"{SFX}/cs_shot_laser.ogg")
cpy(f"{SCI}/laserRetro_004.ogg", f"{SFX}/cs_shot_minigun.ogg")
cpy(f"{SCI}/explosionCrunch_001.ogg", f"{SFX}/cs_boom.ogg")
cpy(f"{SCI}/lowFrequency_explosion_000.ogg", f"{SFX}/cs_boom_big.ogg")
cpy(f"{GUN}/Impact 15.wav",  f"{SFX}/cs_hit.wav")
cpy(f"{IMP}/impactGlass_heavy_000.ogg", f"{SFX}/cs_shield_crack.ogg")
cpy(f"{IMP}/impactBell_heavy_001.ogg", f"{SFX}/cs_crit.ogg")
cpy(f"{SCI}/slime_001.ogg", f"{SFX}/cs_kill_big.ogg")
cpy(f"{RPG}/handleCoins.ogg", f"{SFX}/cs_coin.ogg")
cpy(f"{DIG}/pepSound3.ogg", f"{SFX}/cs_xp.ogg")
cpy(f"{DIG}/powerUp12.ogg", f"{SFX}/cs_levelup.ogg")
cpy(f"{DIG}/powerUp9.ogg", f"{SFX}/cs_heal.ogg")
cpy(f"{UI}/click1.ogg", f"{SFX}/cs_buy.ogg")
cpy(f"{UI}/mouseclick1.ogg", f"{SFX}/cs_draft.ogg")
cpy(f"{UI}/rollover1.ogg", f"{SFX}/cs_hover.ogg")
cpy(f"{DIG}/lowDown.ogg", f"{SFX}/cs_error.ogg")
cpy(f"{DIG}/phaserDown1.ogg", f"{SFX}/cs_death.ogg")
cpy(f"{SCI}/forceField_001.ogg", f"{SFX}/cs_aura.ogg")   # the wraith hum
cpy(f"{SCI}/forceField_003.ogg", f"{SFX}/cs_shield_up.ogg")
cpy(f"{SCI}/thrusterFire_000.ogg", f"{SFX}/cs_charge.ogg")
cpy(f"{SCI}/computerNoise_003.ogg", f"{SFX}/cs_burn.ogg")
cpy(f"{GUN}/Flash Gun 1.wav", f"{SFX}/cs_flash.wav")
cpy(f"{RPG}/metalClick.ogg", f"{SFX}/cs_sell.ogg")

# ---------------------------------------------------------------- MUSIC map
conv(f"{MUSDIR}/desert_loop.mp3", f"{MUS}/cs_desert_day.ogg", "128k")
conv(f"{MUSDIR}/manaosdrone1.ogg", f"{MUS}/cs_desert_night.ogg", "128k")
conv(f"{MUSDIR}/musicbox/musicbox3_sad_tune.ogg", f"{MUS}/cs_park_day.ogg", "128k")
conv(f"{MUSDIR}/aurora.mp3", f"{MUS}/cs_park_night.ogg", "128k")
conv(f"{MUSDIR}/Cinematic_percussion_loop_2.wav", f"{MUS}/cs_boss.ogg", "160k")
conv(f"{RAW}/sfx/call_to_war.wav", f"{SFX}/cs_wave_horn.wav", trim=(0, 4.0))

# ------------------------------------------------------- synthesized gaps
SR = 44100

def env(n, a=0.01, r=0.3):
    e = np.ones(n)
    an, rn = max(1, int(a * SR)), max(1, int(r * SR))
    e[:an] = np.linspace(0, 1, an)
    e[-rn:] *= np.linspace(1, 0, rn)
    return e

def wav_write(path, wave, vol=0.55):
    wave = np.clip(wave * vol, -1, 1)
    data = (wave * 32767).astype(np.int16)
    st = np.column_stack([data, data])
    import wave as wavmod
    with wavmod.open(path, "w") as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(SR)
        f.writeframes(st.tobytes())
    report.append((os.path.basename(path), "SYNTH", ff(path)))
    print("syn", os.path.basename(path), "%.2fs" % (len(wave) / SR))

# cs_hurt: the player's grunt - descending square grunt + noise
t = np.linspace(0, 0.28, int(SR * 0.28), False)
sq = np.sign(np.sin(2 * np.pi * (210 - 140 * t / 0.28) * t))
noise = np.random.default_rng(7).uniform(-1, 1, len(t)) * 0.35
wav_write(f"{SFX}/cs_hurt.wav", (sq * 0.7 + noise) * env(len(t), 0.005, 0.15))

# cs_boss_roar: layered saw growl + sub + noise, 1.4s
t = np.linspace(0, 1.4, int(SR * 1.4), False)
f0 = 68 - 22 * t / 1.4
ph = 2 * np.pi * np.cumsum(f0) / SR
saw = 2 * ((ph / (2 * np.pi)) % 1) - 1
growl = saw * (0.6 + 0.4 * np.sin(2 * np.pi * 13 * t))
sub = np.sin(ph / 2)
nz = np.random.default_rng(9).uniform(-1, 1, len(t)) * 0.25
wav_write(f"{SFX}/cs_boss_roar.wav", (growl * 0.6 + sub * 0.5 + nz) * env(len(t), 0.05, 0.5), 0.6)

# cs_frost: icy shimmer - high sines + glass noise burst
t = np.linspace(0, 0.5, int(SR * 0.5), False)
icy = (np.sin(2 * np.pi * 1860 * t) + np.sin(2 * np.pi * 2480 * t) * 0.7
       + np.sin(2 * np.pi * 3120 * t) * 0.4) / 2.1
nz = np.random.default_rng(11).uniform(-1, 1, len(t)) * 0.18 * env(len(t), 0.002, 0.35)
wav_write(f"{SFX}/cs_frost.wav", (icy + nz) * env(len(t), 0.004, 0.38))

# cs_rail: charge-up + crack
t1 = np.linspace(0, 0.35, int(SR * 0.35), False)
charge = np.sin(2 * np.pi * (300 + 2400 * t1 / 0.35) * t1) * env(len(t1), 0.02, 0.05)
t2 = np.linspace(0, 0.22, int(SR * 0.22), False)
crack = (np.sign(np.sin(2 * np.pi * 120 * t2)) * 0.5
         + np.random.default_rng(13).uniform(-1, 1, len(t2)) * 0.7) \
         * env(len(t2), 0.001, 0.18)
wav_write(f"{SFX}/cs_rail.wav", np.concatenate([charge * 0.5, crack]))

# cs_tick (aura damage tick) - low thump
t = np.linspace(0, 0.16, int(SR * 0.16), False)
wav_write(f"{SFX}/cs_tick.wav", np.sin(2 * np.pi * 110 * t) * env(len(t), 0.002, 0.12))

# ------------------------------------------------------------- verification
ok = 0
for name, src, dur in report:
    if dur <= 0:
        print("!! BAD AUDIO:", name, "from", src)
    else:
        ok += 1
print(f"AUDIO PIPELINE: {ok}/{len(report)} files verified")

import sys
sys.stdout.flush()
os._exit(0)
