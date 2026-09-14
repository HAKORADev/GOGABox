# HEAVY WAR — journal (03)

> Append-only. Newest at the bottom. Every pass adds its block:
> DONE / LEARNED / WRONG / NEXT. This file is how a fresh context resumes
> in one read.

---

## Pass 0 — 2026-09-14 — the setup

DONE:
- Repo resumed, laws re-read (AGENTS.md 1-31, ADDING_A_GAME, BOX_CORE_DESIGN).
- The mission folder + the GDD (`../heavywar.md`) + this journal born.
- THE PACK BLOCKER FOUND: the owner's Drive file is ToS-flagged at
  Google's side — `/view` = 403 with the ToS wall text, `uc?export=download`
  = 404. Nobody can download it, not just this sandbox. The owner was
  asked to re-upload (GitHub into the repo = the sure path).
- Architecture set: data-driven from day one (`heavywar_data.gd`), so the
  pack lands as swap + tune (see 02_PLAN.md).

LEARNED:
- Google's ToS wall text (translated from the zh page): "sorry, this item
  violates our Terms of Service, so you cannot access it".

WRONG (avoid repeating):
- First download attempts hit `drive.usercontent.google.com` directly with
  a guessed `confirm=t` — 404 wasted a call; probe `/view` FIRST to see
  the real wall before crafting endpoints.

NEXT:
- Build pass 1: the road + the tank + the gun + the sky skeleton.
- Then passes 2-8 per 02_PLAN.md, each with its qa phase.
- When the pack lands: 01_STUDY.md fills with the art/XML findings and the
  swap + tune pass runs.

---

## Pass 0.5 — 2026-09-14 — THE PACK LANDED + full study

DONE:
- The owner's new link worked (7z, password "heavy"). `drive.usercontent.
  google.com/download?id=...&export=download&confirm=t` = clean 20.5 MB pull
  (gdown was ToS-blocked on this file too, but plain usercontent was not).
- py7zr FAILED on this archive (`LZMAError: Invalid or unsupported options`).
  Standalone 7zz 25.01 binary (7-zip.org, no sudo) extracted it fine:
  999 files, 30 MB -> `heavywar_src/extracted/HeavyWeapon/` (outside repo).
- Full pack study done, digest script at `scripts/hw_study.py` ->
  `heavywar_src/DIGEST.json`. Findings -> `01_STUDY.md`:
  21 enemies (armor/points/weapon + strip dims), 19 mission levels +
  10 survival sets x 80 waves, 10 bosses with L1/L2 comeback params,
  10 places with 4-layer parallax + prop anims, 465 images, 184 sounds.
- THE USAGE LAW applied to the plan: art = 100% ours (PIL redraw at the
  pack's frame sizes), audio = synthesized, XML = rewritten into our tables.

LEARNED:
- The original's drive.usercontent endpoint still honors `confirm=t` for
  files that gdown refuses — same as the Quaternius folder trick.
- py7zr's LZMA decoder is narrower than real 7zz; always keep the 7zz
  binary at tools/7zip/ in the sandbox for password archives.
- The original XMLs are MALFORMED (multiple roots, stray `"/ attr>` in
  Anims.xml) — a tolerant regex-sanitizing parser is required.
- The pack carries NO drop/RNG tables — pickup logic was compiled. Our
  friend-helicopter cadence is our own design (the GDD's), free of legacy.
- Boss comeback model straight from the data: L2 = armor x2.5-4, fire x0.6.
- 100 fps frame units everywhere (`fire="175"` = 1.75 s); wave `length` is
  scroll px, not seconds.

WRONG (avoid repeating):
- None this pass; the tolerant-parser regex ate a space once (`"\1/>` ->
  `" \1/>`) — caught on the third run.

NEXT (pass 1):
- Scaffold `game/games/heavywar/` (heavywar.gd / heavywar_data.gd /
  heavywar_meta.gd) + registry entry + the GogaGame contract fit.
- THE ROAD + THE TANK + THE GUN + THE SKY skeleton with stand-in shapes,
  then the art tool paints the real slots (pass 1.5).
