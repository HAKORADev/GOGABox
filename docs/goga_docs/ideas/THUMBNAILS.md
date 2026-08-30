# THUMBNAILS — the box-wide thumbnail spec

Owner decisions locked in this chat (v0.1.5 era, pre-v0.1.6 planning).
These are RULES now, not proposals. The "how do we produce them" question is
still open and being thought through with the owner (see the end of this file).

## 1. LOCKED RULES (owner-approved, do not drift)

| # | Rule |
|---|------|
| R1 | **Canvas: 960x640 for every thumbnail** — real games, mystery tile, SOON placeholders, future 3D games, everything. One size to rule them all. |
| R2 | **Real-game thumbnails carry NO baked text** — no game name, no description, no tagline. The tile chrome around the thumb already shows the name in the feed; the poster is pure game. |
| R3 | **If a thumbnail ever needs text** (a future special case), it must use that **game's own font asset** when the game has one; only fall back to the box-wide font (Kenney) when the game ships no font of its own. |
| R4 | Mystery + SOON placeholders live on the same 960x640 canvas (their own shared templates — they are allowed text, they are not real-game posters). |
| R5 | Whatever production method we pick, it must **scale to 3D games** — any method that only works for 2D code-drawn scenes is disqualified long-term. |

Consequences already known:
- The current 480x320 set (6 hand-coded scenes + SOON template in
  `tools/derive_assets.py thumbs()`) is deprecated by R1 and its
  title+tagline pass is killed by R2 — a full re-derivation is coming.
- The menu feed (`menu.gd _add_thumb`) must display 3:2 960x640 assets
  correctly (cover-fit, no stretching, no letterbox) — small UI pass required
  when the new set lands.

## 2. PRODUCTION — the open question (thinking with the owner)

Paths on the table (owner's own framing):
1. **Hand-design in code** (today's approach, upscaled): compose each poster
   from the game's real sprites, review-iterate. Works for 2D, breaks R5
   (3D), and every game costs manual art logic forever.
2. **The overkill**: program an AI/CPU player to actually PLAY every game,
   capture static frames AND dynamic video (hold-the-thumb previews).
   The dream end-state, too heavy to start with.
3. **Real gameplay capture**: run the real game, capture real frames,
   pick winners. Owner note: "using in-game footage is the best way to be
   honest for every player" — and whatever captures stills can later capture
   video, so path 3 is a strict subset of path 2.

Working direction (not yet final): a **capture harness inside the engine** —
run each real game scene offscreen, drive it with a tiny per-game auto-pilot
(a few controls per game), render straight at the target canvas or full-size
then crop, vision-review candidate frames, no text. Same harness later grows
into path 2 (longer runs + video encode) without throwing anything away.

Decision pending with owner: harness details (native 3:2 render vs
full-frame + action-band crop for portrait games), SOON/mystery text policy
confirmation, and which release carries the first batch.
