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
