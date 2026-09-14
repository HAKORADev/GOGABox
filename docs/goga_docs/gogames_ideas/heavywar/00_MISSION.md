# HEAVY WAR — the mission folder

> The owner ordered this subfolder on purpose: "this part of really building
> the full game may take forever from you... the task is huge enough to clear
> your context memory 10s of times". THIS FOLDER IS THE AGENT'S MEMORY.
> Every pass reads it first, every pass appends to it. Never rebuild state
> from scratch — rebuild it from here.

## The files

| file | what lives there |
|---|---|
| `../heavywar.md` | THE GDD — the owner's spec, written once, changed only by the owner |
| `01_STUDY.md` | the original game pack study: art inventory, XML logic findings, integration notes |
| `02_PLAN.md` | the build architecture: passes, systems, data tables, file map |
| `03_JOURNAL.md` | append-only progress log: what was done, what went right, what went wrong, what is next |

## The mission (one paragraph)

Build **HEAVY WAR** — the owner's rogue-like survival rework of the
heavy-weapon-like — as **v040** of GOGABox. Horizontal only. One endless run
through ALL the original's places, shuffled every run, joined by TUNNEL
transitions with calm zones. A friend helicopter drops shields / nukes / laser
components / lives / GOGACoins. A boss every 5 places (+10 bosses, they make
comebacks), each boss pays 1 upgrade point and opens the in-run upgrade menu
(6 upgrades x 5 levels, 30 points total, permanent). Score = kills. Shop =
tank skins + 4 locked upgrades + the laser. Controls: left half swipes the
tank, right half shoots, middle tap = nuke. The original's pack (art / SFX /
music / bare-XML logic) is the study source — landed 2026-09-14 (owner's
re-upload); studied under THE USAGE LAW: zero original bytes ship.

## The state of the pack (updated per pass — READ ME FIRST)

- **2026-09-14: PACK LANDED.** The owner re-uploaded (new Drive id
  `19fK-_fDEruxL6VlzrPZ6-JdBN_ancROJ`, 7z, password "heavy"). Downloaded via
  `drive.usercontent.google.com/download?...&confirm=t` (20.5 MB), extracted
  with the standalone 7zz binary (py7zr choked on its LZMA variant) to
  `heavywar_src/extracted/` — 999 files, OUTSIDE the repo.
- Full study digest done -> `01_STUDY.md` (craft/waves/bosses/places/anims/
  art slots/sounds). THE USAGE LAW in force: zero original bytes enter the
  repo or the APK; art redrawn, audio synthesized, XML logic rewritten.
- The build proceeds data-driven per `02_PLAN.md`, with the pack's numbers
  as the starting tuning.
