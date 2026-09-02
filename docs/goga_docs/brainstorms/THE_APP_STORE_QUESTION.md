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
