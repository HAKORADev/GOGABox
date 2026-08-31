# gogames_ideas — GDDs for the games inside the box

Every game gets ONE markdown file, named after the game's NAME —
`snake.md`, `dario.md`, `xo.md` (lowercase, the game's name, nothing else).

## The journal style (THE rule)

A GDD is a structured JOURNAL, never a living document rewritten in place:

- entries run oldest at the top, newest appended at the BOTTOM
- every entry starts with a timestamp heading:
  `## YYYY-MM-DD HH:MM — short title` (owner-local time)
- the entry records what was decided / changed / learned, then the content
- never silently edit an older entry — add a new entry that supersedes it;
  the accretion IS the design story, and future-you can diff decisions

## What an entry carries

Pitch, core loop, controls, scoring / GOGACoin economy, unlock & meta hooks,
art direction, audio direction, open questions for the owner — whichever of
those the timestamp is about. One entry can be one paragraph; a big rework
day writes a big entry.

The full name dump of future game ideas lives in `FUTURE_GAMES.md` (the
parking lot — names only, nothing scheduled). A GDD file appears here the
moment the owner picks a game and real work begins.

When a game is approved for a release, it also gets a task entry in the
matching `plans/PLAN_vX.Y.Z.md`.
