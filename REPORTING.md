# REPORTING — github issues, a game id, and what a report is

The platform has NO in-app moderation, NO report buttons, NO takedowns
by mood. Reports are GITHUB ISSUES — public, structured, machine-triage
— and they exist to fix broken THINGS, not to police taste.

## How to report

Open an issue on the repo the thing belongs to, using the template
(`.github/ISSUE_TEMPLATE/game-report.md`). A CORRECT report carries:

1. **the game id** — the full long id, e.g.
   `gogabox_github-<user>_<ns>.<name>.<n>_<tier>`. It is printed in the
   game's discover page and is the installed folder's name under
   `GOGAs/games/`. An id can be anything (`shit.how.nah`-shaped is
   legal) — that is WHY the report carries it verbatim instead of a
   description.
2. **what is broken** — the crash text, the wrong behavior, the file
   that refuses, the version numbers.
3. **where it happened** — the platform (phone/PC), the box version.

## Where the report goes (the triage law)

| the thing you report | the repo that owns it |
|---|---|
| a GAME (crashes, bugs, wrong art, a broken package) | the GAME OWNER's repo — the github user in the game's id. The official app repo's triage closes and points there. |
| the APP (the box itself: discovery, downloads, the wallet, the LAN, the update flow) | the official repo (HAKORADev/GOGABox) |
| a SOURCE that stopped serving | the SOURCE's repo (its owner fixes it) |

The CI/issue tooling reads the game id, finds the owner from the id,
and routes: game reports belong to the game owner, app reports to the
official repo. The platform's role ends at the routing — the fix lives
with the code's owner.

## What a report is NOT (the refuse list, verbatim intent)

These are NOT reports and will be closed as such:

- "I do not like it."
- "This is illegal based on my country."
- "This is wrong in my religion."
- "That game is very bad to my family/kids."
- Any other ask for moderation, removal or filtering of a game that
  works.

The answer is the platform's oldest one: **games are not a must — no
game comes with the app. Do not like it = be away from it.** Nobody is
required to download anything, the box ships with zero games baked, and
the age + content tags exist so a household can decide at the play
button — not so a crowd can decide for everyone.

The same rule reads upward: the platform takes no content lines of its
own, so it also takes no moderation requests in any direction.
