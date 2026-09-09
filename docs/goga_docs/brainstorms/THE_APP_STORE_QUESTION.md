# THE APP STORE QUESTION — GOGABox growing up

Owner brainstorm, dumped verbatim-first during the v0.2.8 round (his order:
"make a brainstorm file in the correct folder so i do not forget a detail
later, do this before working on the next update!"). NOTHING here is
committed for a release yet — this file exists so no detail is lost while
the owner thinks. Rules / agreement / moderation are explicitly DEFERRED:
"you and me can not manage updating 2048 and reworking XO then add rules
and content moderation at one pass".

## The spark (owner, near-verbatim)

> "at this point GogaBox is starting to be its own app store, funny. The
> more funnier thing is that we could really make each game use a different
> ad ID to give different devs their money from in-game banner ads and
> rewarded ads while our GOGABox makes money from per-3-rounds ads.
> I guess this app really has many potentials!!"

## 1. The publishing-corner ambition

- GOGABox started as a game box for our own ports; the shape (registry,
  reveal chains, shop, per-game economy) already behaves like a store
  shelf.
- If third-party games ever join, the box becomes a publishing corner:
  curated games inside one app, one wallet, one ruleset.
- Owner is aware this drags real platform responsibilities with it
  (see 4).

## 2. The ad-revenue split dream (per-game ad units)

- Each game could carry ITS OWN ad unit ID (banner + rewarded), so a
  contributing dev earns from their own game's inventory.
- GOGABox keeps the box-level inventory: the per-3-rounds ads (the
  interstitial pacing that already exists between runs) and any
  box-chrome placements.
- Engineering shape when the day comes: registry gains per-game
  `ad_unit` overrides; ads.gd resolves the unit by the active game id;
  the box-level units stay the fallback. No network/account work until a
  real second dev joins.

## 3. The age gate idea

- Ask the age when the app starts: 3 years ... 21+ (owner: "from 3 years
  to +21").
- The age becomes a filter: games and in-game CONTENT can be filtered or
  internally trimmed so everything stays suitable and manageable.
- Open question the owner is still chewing: how strict each band is, what
  gets hidden vs what gets trimmed, and whether the answer is stored or
  re-asked. NOT designed yet — parked here on purpose.

## 4. The content-policy tension (the gambling example)

- While sketching an XO shop, most of the owner's ideas drifted to
  virtual gambling / betting. His call: "this will be too much for a
  gamebox that is supposed to not contain AO content" — the ideas are
  SHELVED, XO ships with no shop this round.
- But he immediately poked the hole himself: "but who said GOGABox is
  kids-only too?" — and if it grows into a publishing corner it may end
  up hosting porn, gore, or intense psychological horror games.
- The question that must be answered BEFORE any of that: what are the
  app's rules? ("so what is our rules for this app first")

## 5. What is explicitly deferred (owner's own sequencing)

1. NOW (v0.2.8): finish 2048 (feedback round) + rework XO. No policy
   work in this pass.
2. NEXT: the owner drafts his thoughts on rules / user agreement /
   content moderation, then instructs; we implement the age gate +
   filtering + the agreement screens in their own update(s).
3. LATER: return to XO and decide what its shop (if any) becomes, now
   with real rules to design against.

## 6. Small facts worth keeping

- XO (the fresh rework) already behaves like the "per-3-rounds" beat:
  one GOGACoin lands on the board every 3 rounds — the owner tied the
  coin cadence to the same rhythm he wants the box ads on.
- The virtual-gambling shelving is a PRECEDENT: the box has a de-facto
  content line today (no gambling), even before any written rules.
- If per-game ad IDs land someday, the XO-style per-round economy
  (fees, coins, bonuses) is already isolated per game — the money
  plumbing would follow the same seam.

## 7. THE ARCHIVE (v0.3.7-2) - the age system + GOGAds, preserved whole

The owner shipped both systems in v0.3.7-1, tested them on device, and
pulled them the same day ("FUCK THAT REMOVE THESE THINGS AND FIX THESE
STUFF SO WE CAN WORK ON NEW GAMES"). His own words on why: a place with
no lock between +3 and +21 is a +21 place; he does not want anyone
arguing about what "may suit" whom; GOGABox stays "for everyone" - no
gambling, no gore, no porn in the shipped box; and managing content
bands is too much for one person ("there is already olymptrade and
1xbet for gambling bruh"). This section keeps the FULL specs so a
future round can bring either back without reinventing it.

### 7.1 THE AGE SYSTEM (removed in v0.3.7-2)

What it was: the +3..+21 content ladder. Every registry entry wore
`"age": "3".."21"`; the box shipped as +9 (BOX_MAX_AGE) - anything
stricter was hidden from the shelf, the feed and the search by
`age_allowed()`. The settings carried THE "!" DOOR: first knock = the
agreement sheet (placeholder text, `agreement_ok` progress key, DISAGREE
did nothing on purpose), then the AGE RATES sheet with the full ladder
and the ILLEGAL row visibly gated (disabled button, "the gate stays
closed"). The search menu filtered by age chips (Meta.AGES +
`used_ages()`); the guide and the pre-play page showed the age chip.

The tier texts (the owner's own legal descriptions, written as registry
code comments):

- +3 EVERYONE - no specified age. Games for any human alive: no violence
  beyond cartoon slapstick, no reading walls, no scares, nothing that
  needs life experience.
- +5 SIMPLE - designed so a 5-year-old can hold it: big targets, one
  verb, no fail spirals, no text puzzles. Still clean for everyone.
- +7 MODERATE - moderate puzzles and simple hitting combats or basic
  shooting WITHOUT any graphical content: no blood, no bone sounds, no
  weird stuff. Losing is friendly.
- +9 LITTLE VIOLENCE / TACTICAL - a bit of hitting that reads as real,
  tactical loadouts, consequences on screen - but nothing graphic. THE
  BOX'S CEILING at the time ("even shadow fight is +7 and we are just
  going to add some effects, make it +9 so it not get removed").
- +12 YOUNG TEENS - sexual innuendo, or intense violence with dead
  bodies and some graphical content, or basic horror games.
- +16 TEENS - half nudity (topless / back nudity), or intense violence
  with graphical injuries and screaming, or high-level horror games.
- +18 MATURE - direct gore, direct nudity, soft porn, psychological-
  intense horror, virtual gambling, fantasy illegal trading (drugs,
  weapons, thievery) and anything that direct.
- +21 ADULT ONLY - direct hard porn, intense gore with no meaning or
  illogical roles, realistic gambling simulations, real illegal
  trading, political-sensitive games with real-world scenarios.

Legacy notes: the OLD pre-ladder tags were `everyone` / `kids` / `teens`
(labels EVERYONE / KIDS 8+ / TEENS 12+, icons age_everyone/age_kids/
age_teens.png - the pngs left with the system). Cosmic Spud wore +9 per
the owner (down from a planned +12). The v0.3.7-1 GOGAds tag taxonomy
(next section) carried the +12+ CONTENT tags - porn, gore, illegal
trading, gambling, intense horror - all removed with it; GOGABox stays
"for everyone" (no gambling, gore or porn anywhere in the shipped box).

If it ever comes back: rebuild from this section + the v0.3.7-1 plan
(PLAN_v0.3.7-1.md) - registry keys (`age`, BOX_MAX_AGE, age_num/
age_allowed), the Meta.AGES table, the ui_kit age chip branch, the menu
"!" door (_open_bang_door / _open_age_rates), the AGE search row, the
guide + pre-play AGE sections, and the age pngs in assets/meta/.

### 7.2 GOGADS - the in-house ad layer (removed in v0.3.7-2)

What it was: the owner-managed ad framework, autoload `GOGAds`
(`game/core/gogads.gd`, 313 lines). THREE ad sources:

1. BAKED ads - a shipped index at `assets/gogads/index.json` (the box's
   own promos; shipped with ad_arcade.png / ad_puzzle.png).
2. DEV ads - registered at runtime by any GOGABox game/dev
   (`register_dev_ad()`); the shared system where a dev links their own
   site and earns directly; `only_me` loyalty kept the break inside the
   dev's own games.
3. LINK ads - open the link over the DEVICE browser (nothing in-app
   beyond the door).

The break config lived PER GAME in the registry:
`"gogads": {"end": {"frequency": 3, "total": 6, "tags": [...],
"level_min": 0, "level_max": 1}}` - states `start`/`end`; frequency =
every Nth run in that state, total = the daily cap (12AM lazy reset).
The host (`host_node.gd`) fired `GOGAds.maybe_interstitial(id, state)`
at the game start and at the death state. The picker matched an ad's
tags/subs against the break's tags and the game's level via the
WTF-OMETER (content intensity 0..3: 0 clean .. 3 adult; the baked index
only ever carried 0-1, so a +2 horror break found nothing - by design).
The ledger (`snake|end` style keys) counted runs + shows per state per
day. Snake shipped wearing the only break (death state, every 3rd run,
6 a day, arcade/casual tags).

The Unity Ads integration (plugins/unity_ads + the house 52dp banner)
is a DIFFERENT, older system - it stayed in the box. Only GOGAds died.

If it ever comes back: rebuild from this section + PLAN_v0.3.7-1.md -
the autoload, the index schema, the picker/ledger, the registry key,
the two host hooks, and the project.godot autoload line.

### 7.3 The decision record (the owner's own sequencing)

- The age question stays UNDECIDED at the box level: whether GOGABox
  offers mixed 3-21 content or stays strict per game - "i will remain
  the state of GOGABox uncleared".
- He may still "end up putting some gambling stuff and call it a day" -
  risk-free VIRTUAL gambling was toyed with (power-ups, visuals, SFXs,
  modes) and dropped ("nah... there is already olymptrade and 1xbet").
- The +12+ tag taxonomy (porn/gore/illegal trading/gambling/intense
  horror) is REMOVED from the search menu and the docs - the app is
  "for everyone" until he says otherwise.
- The fear that drove the pull: "i may say again to re-add these things
  which will make us fall into a bad loop" - this archive exists so the
  loop, if it happens, costs one read instead of one rebuild.
