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
music / bare-XML logic) is the study source — BLOCKED at Google Drive
(ToS flag), re-upload pending; the build continues with data-driven
stand-ins until the pack lands.

## The state of the pack (updated per pass — READ ME FIRST)

- **2026-09-14: DRIVE LINK BLOCKED.** `drive.google.com/file/d/15YApMycQamq_6uHru_HV9ZO3TR-U3DHz`
  returns Google's hard wall: "sorry, this item violates our Terms of Service"
  (server-side flag on the FILE — not a bot wall, not our IP alone; the
  anonymous endpoints `/view` = 403, `uc?export=download` = 404).
  **Nobody with the link can download it.** The owner was asked to re-upload
  (GitHub upload into the repo = the sure path; a re-zipped fresh Drive copy
  or another host as alternatives).
- Until the pack lands: the game builds **data-driven** (every enemy, place,
  boss, drop table and value lives in `heavywar_data.gd` / the study tables),
  with house-style code-drawn art + synthesized SFX as the interim layer.
  The pack's arrival becomes a SWAP + TUNE pass, not a rewrite.
