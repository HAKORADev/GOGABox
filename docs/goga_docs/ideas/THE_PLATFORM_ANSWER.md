# THE PLATFORM ANSWER — GOGABox as a store/platform (the hidden plans, revealed in the v041-3 era)

> The reveal file. The owner kept this work hidden ("the hidden work that was
> planned once v041 started btw i guess or even slightly before it") and
> revealed it in full on 2026-09-24, right after the v041-3 r2 correction
> round shipped. It is the direct sequel to THE_APP_STORE_QUESTION.md (the
> v0.2.8 spark + the age/GOGAds archive) and it lives next to
> LAN_MULTIPLAYER.md (updated the same day: LAN goes cross-platform + tagged).
> DOCUMENT ONLY — nothing here is scheduled, designed for real, or built.
> The owner's own working agreement: "we are just going to talk about the
> plans step by step together until we have something suitable so we do not
> do refactor over another" — no code moves until the talk converges.

## THE OWNER'S ORIGINAL MESSAGE (verbatim, preserved whole)

The reveal message, saved unedited — the owner: "i feel we may need to look
at my original words over and over". Kept exactly as sent (2026-09-24):

```
wait, you have actually finished v041-3 second round, anyway, here it is the full hidden work/s plan/s:
(ok i love drama, are you READY TO SEE THE HIDDEN PLANS GET REVEALED? ARE YOU READY TO SEE THE PLOT TWIST HAPPENS IN REAL-TIME IN FRONT OF YOUR EYES? IF YOU ARE, JUST TELL ME SO I GIVE YOU THE HIDDEN WORK PLANS FIRST BEFORE WE EVEN START DO SOMETHING👨🏻‍🔧🔥)
...
...
ummmm, you will document this next to a file next to the LAN and the appstore-thing doc files, make this as one md dense with everything, i want you also to save the full original message i wrote in that file at the start, i feel we may need to look at my original words over and over, then after it, write the documentation of the things like all other files, there is a mention in this plans that LAN will be cross-platform, so in your way, go to the lan file, and make the documentation contain that LAN support will be tagged with the platform and how many players supported in the game (GOGABox limits to 4 in one session anyway) also this means LAN will get it's own tags and like that
all of these things are documentation only, you will not do any work for now
after you write all things and read it accurately
i want you to return and give me your massive opinion on my all plans👨🏻‍🔧 if you looked at the old appstore-thing-like doc file and looked at the old git history of first time making windows build then removing it, then the ideas of GOGABox as store comes and go, and the last work of going real open-source and license updates, you will feel everything connected amazingly! take your time understanding these things, if you feel any historic moment worth noting in the file, there is no problem to put it in a correct place, also, about the ideas, i guess the sdk will be shared dll files one for the developers and the same will be used for the games for the end user, as same as steam api and others i mean like google play work too, also i guess a game can be many files, or a game could be direct .exe or subfolder in game folder containing the game itself, while another subfolder in the same main game folder containing the dlls, the index, all GOGABox-related stuff next to the subfolder of the discover which will be for the...obviously the discover feed, i guess a game being .exe and GOGABox be platform like steam/epic games where we provide full stuff to developers from resolution to positioning to everything, they use our plugin or somehow our future-thing and it makes game development much faster without cutting creativity but giving one formal look of GOGABox stuff with overrides if they want, also the developer testing locally, we can make it support local paths and the binary checks everything, so we simulate full github-side repo discovery and installing and updating work accurately, why this? because github is perfect and we trust it and we can do nothing to it, so we are ready to make our own side so we just trust the process of github later, also i guess we can use tricks to bypass github api limitations, like using raw http search stuff and things like, i do not know what the tech actually called but it is something purely automated, we search for direct web URL of a .json or a file we know will be existing in a repo that is containing game structure so we do not consume the api limits
...
...
also what i said currently still be considered part of the plans! note that i have not yet stayed on one thing, but i know age rating and filters will return, i do not know how a game will be truly packaged to fit in GOGABox or how we will make a user push files using a token that pushes specific stuff and how it could happen for real
sooo, we are just going to talk about the plans step by step together until we have something suitable so we do not do refactor over another🙂👌🏻
take your time on the whatever is this!🙂🙌
```

## THE ARC — why everything connects (the history the owner pointed at)

The owner: "if you looked at the old appstore-thing-like doc file and looked
at the old git history of first time making windows build then removing it,
then the ideas of GOGABox as store comes and go, and the last work of going
real open-source and license updates, you will feel everything connected
amazingly!" The connection, laid out:

| when | what | the mark it left |
|---|---|---|
| v0.2.8 | THE SPARK — "at this point GogaBox is starting to be its own app store, funny" | THE_APP_STORE_QUESTION.md: the publishing corner, the per-dev ad units, the age gate idea, the rules question |
| v0.3.7-1 → v0.3.7-2 | THE FIRST STORE-SHAPED ATTEMPT — the +3..+21 age ladder + GOGAds (dev ads, per-game breaks) shipped, then pulled the same day | archived whole in THE_APP_STORE_QUESTION.md §7; the box chose "for everyone"; the owner's fear named it: "i may say again to re-add these things which will make us fall into a bad loop" |
| 2026-08-30 (70335dcf) | THE REPO REWORK — renamed GOGABox-only, AS-IS license, docs/goga_docs planning home, "asset-store trials" | the store idea's first quiet rehearsal, at the repo layer |
| 2026-09-06 (81351aca → 0dbc1289) | THE WINDOWS FORGE + the first Windows build (v0.3.4-3) | the two-platform wish, one day old |
| 2026-09-06 (805b041a) | THE GREAT UN-WINDOWING — v0.3.4-4 android-only; the owner's law: "no windows builds, no way to make money from them, focus only on Android" | the PC code, the keyboard controls, the os tags all deleted; THE ANDROID-ONLY LAW written into RELEASE_LAW.md |
| 2026-09-19 (16db01d7) | THE OPEN-SOURCE ROUND — v0.4.0-16: MIT + 0 ads + THE WINDOWS RETURN | the commit's own archaeology: the un-windowing's "only reason — 'no way to make money from them' — is dead today"; the whole monetization stack removed; the box fully offline; GOGACoins the only currency |
| 2026-09-19/20 (883ba438, f85ecbc1) | the owner's first Windows test round (v040-17) + the v041 CI green (the windows zip 123.1MB + both APKs) | the PC seat became real again |
| v041 — v041-3 | the 3D seat (Tower Ball) + Tower Destroyer (the CPU-multiplayer test bed — the verdict: the enemies "somehow good", the game itself frozen) | the four-seat PlayerSeat pattern — "the future LAN seat swaps cpu for network and nothing else" |
| 2026-09-24 | THE REVEAL — this file | the store idea returns the third time, now with mechanics: an SDK, a packaging shape, a discovery engine, a trust model |

The pattern the owner felt: the store idea comes and goes, and every return
is more concrete. v0.2.8 was a feeling ("funny"). v0.3.7 was an
infrastructure attempt pulled for honest reasons. The open-source round then
removed exactly the things that made a third-party store impossible — the
ads (third-party dev revenue over box ads would have been a legal and moral
swamp), the closed license (third parties cannot build for a box they cannot
read), the missing Windows seat (half the developer audience gone). The
reveal lands on a box that is MIT, offline, 0-ads and two-platform: a clean
room. The idea did not circle — the runway was being cleared each time.

## THE LAWS (shaped from the reveal, all DOCUMENT-ONLY)

- **THE TRUST LAW**: "because github is perfect and we trust it and we can
  do nothing to it, so we are ready to make our own side so we just trust
  the process of github later". GitHub is the backend of record — hosting,
  versioning, distribution. GOGABox builds ONLY its own side (the binary,
  the formats, the flows) and trusts GitHub's side wholesale. Nothing is
  re-invented that GitHub already does perfectly.
- **THE LOCAL SIMULATION LAW**: "the developer testing locally, we can make
  it support local paths and the binary checks everything, so we simulate
  full github-side repo discovery and installing and updating work
  accurately". The dev loop works from local paths; the GOGABox binary
  validates everything itself; the full GitHub-side pipeline (discovery →
  install → update) is simulated locally, accurately, BEFORE any real
  GitHub-side dependence. The point: when the real side arrives it is not a
  new system — it is the simulated one pointed at a real URL.
- **THE NO-API-LIMIT LAW** (the raw trick): "we can use tricks to bypass
  github api limitations, like using raw http search stuff ... we search for
  direct web URL of a .json or a file we know will be existing in a repo
  that is containing game structure so we do not consume the api limits".
  Discovery fetches KNOWN, CONVENTION-PLACED files over raw HTTP (direct
  web URLs) instead of calling the API — purely automated, and the rate
  limits are bypassed by construction. The owner's honesty stands in the
  file: "i do not know what the tech actually called but it is something
  purely automated" (the shape is convention-over-API: a well-known file
  name IS the API).
- **THE SDK LAW**: "i guess the sdk will be shared dll files one for the
  developers and the same will be used for the games for the end user, as
  same as steam api and others i mean like google play work too". ONE shared
  set of DLLs, dual-use: developers build against it, and the same DLLs ship
  inside the game for the end user. The Steam API shape (steam_api.dll
  ships with each game and talks to the platform) and the Google Play
  services shape, at once.
- **THE PACKAGING LAW (draft)**: "a game can be many files, or a game could
  be direct .exe or subfolder in game folder containing the game itself,
  while another subfolder in the same main game folder containing the dlls,
  the index, all GOGABox-related stuff next to the subfolder of the discover
  which will be for the...obviously the discover feed". A game is a main
  folder that carries the game itself as (a) many files, (b) a direct .exe,
  or (c) a game subfolder — beside a DLLs subfolder, an index, all
  GOGABox-related files, and a discover subfolder for the discover feed.
  NOT FINAL — see THE OPEN QUESTIONS.
- **THE FORMAL LOOK LAW**: "gogabox be platform like steam/epic games where
  we provide full stuff to developers from resolution to positioning to
  everything, they use our plugin or somehow our future-thing and it makes
  game development much faster without cutting creativity but giving one
  formal look of GOGABox stuff with overrides if they want". The platform
  hands developers everything mechanical — resolution, positioning,
  everything — so game development gets much faster; creativity is never
  cut; the formal GOGABox look is the default; overrides are allowed
  everywhere.
- **THE LAN CROSS-PLATFORM LAW**: the reveal carries LAN forward — LAN will
  be cross-platform (phones and the PC build in one session), and LAN
  support becomes TAGGED data: each game's LAN support is tagged with the
  platform(s) and the supported player count, and LAN gets its own tags.
  The 4-player session ceiling stands. Written into LAN_MULTIPLAYER.md the
  same day (THE CROSS-PLATFORM UPDATE section).
- **THE RETURNING LAWS**: "i know age rating and filters will return". The
  age ladder and the filters are not dead — they are parked (the full specs
  live in THE_APP_STORE_QUESTION.md §7). A third-party store cannot stay
  "for everyone" by silence forever; when the doors open, the age question
  walks back in. The owner knows it; the archive exists so the return costs
  one read, not one rebuild.
- **THE FLUIDITY DISCLAIMER (the owner's own)**: "note that i have not yet
  stayed on one thing" — every law above is a shape, not a decision. The
  file exists so no detail is lost while the talk converges, exactly the job
  THE_APP_STORE_QUESTION.md did in v0.2.8.

## THE SHAPE OF A GAME (draft tree, from the owner's words)

```
<games root>/
  some_game/                # the main game folder
    <the game itself>       # a subfolder ... or a direct .exe ... or many files (all three allowed)
    dlls/                   # the shared GOGABox SDK dlls this game talks to
    index                   # the game's index/manifest GOGABox reads
    gogabox/                # all GOGABox-related stuff
    discover/               # the discover feed's material for this game
```

Reading notes (documentation, not decisions):

- The DLLs living INSIDE each game folder is the side-by-side versioning
  instinct: every game carries the SDK version it was built against, the way
  Steam games each ship their own steam_api dll — no global SDK version
  skew, ever.
- The discover subfolder INSIDE the game folder couples the store's feed
  material to the game's repo — the feed material updates with the game.
  Simple, automatable, and worth re-examining when the feed design starts
  (it is the piece most likely to move).
- The three allowed game shapes (many files / direct .exe / a game
  subfolder) keep the door open for engines beyond GOGABox-made ones.
- The index is the file the raw trick fetches: the known .json the
  discovery reads so the API is never touched.

## THE DEVELOPER LOOP (draft, from the owner's words)

1. The developer builds a game against the SDK (the shared DLLs), the
   platform providing resolution/positioning/everything by default with
   overrides where wanted.
2. Locally: the game folder sits at a LOCAL PATH; the GOGABox binary checks
   everything — the index, the structure, the SDK ("the binary checks
   everything").
3. The binary simulates the FULL GitHub-side pipeline accurately:
   discovery, installing, updating — all of it, against the local folder.
4. Later, the same flow points at a real GitHub repo: the raw trick
   discovers the known files without burning API limits, GitHub hosts,
   GOGABox trusts the process.

The design's wisdom, worth naming: the binary is the source of truth for
VALIDATION; GitHub is the source of truth for DISTRIBUTION. Local-first
means every rule the binary enforces locally is exactly the rule the remote
flow will enforce — the simulation is the contract.

## THE OPEN QUESTIONS (the owner's own unsolved list — the talk's agenda)

- **THE TRUE PACKAGING**: "i do not know how a game will be truly packaged
  to fit in GOGABox" — the tree above is a sketch; the real contract (what
  is required, what is optional, what validates) is unbuilt.
- **THE TOKEN PUSH**: "how we will make a user push files using a token
  that pushes specific stuff and how it could happen for real" — the
  submission path. Who gets a token, what the token may push, what reviews
  it, where it lands. Unanswered — and it is the question that drags every
  platform responsibility with it (the same tension the appstore file
  circled in v0.2.8: "so what is our rules for this app first").
- **THE AGE RETURN**: the ladder will come back (THE RETURNING LAWS) — the
  shape is unknown: hidden vs trimmed, stored vs re-asked (the exact
  questions §3 of the appstore file parked on purpose).
- **THE DISCOVER SHAPE**: what the feed shows, where its material truly
  lives, how a game earns its place on it.
- **THE SDK RUNTIME MAP**: the DLL story is Windows-shaped; the Android
  twin (the .so / GDExtension / GDScript-side equivalent) is not discussed
  yet — and the box is a two-platform ship since the Windows return.

## THE GOGAPROFILE SEED (added by the owner, the v042 order — document + seed infra)

The v042 LAN order carried a platform idea with it ("based on the
appstore-idea doc file, an idea hovered in my mind"): a LOCAL PLAYER
PROFILE, shaped like a GitHub profile, wearing exactly:

- **PFP** — the simple drawn one-guy figure (the LAN spec's PFP LAW), in
  pickable drawn variants;
- **description** — a short bio;
- **supporting links** — a few http(s) strings (the future dev's shops,
  repos, pages);
- **age** — the number only (the age-system return stays a separate
  question);
- **role** — `gamer` / `developer` / **`owner` (unique — one device)**;
- **gender** — male / female / **"other"**.

The laws around it, in the owner's own moves:

- **NO USERNAME. NO DATABASE.** There is only a NAME (the LAN name law:
  EN letters, no emoji, 20 chars max) — "there is no database, so why there
  will be a profile?" — for the DEEP INFRA: "a developer in github could
  later make a folder for the profile like GOGAProfile/ ... and for
  hobbyists when push locally from the app". The profile is the platform
  account that exists BEFORE the platform, exactly the sequel shape this
  file predicts: when the token-push question (THE OPEN QUESTIONS) gets its
  answer, the answer's user side already exists.
- **THE LOCAL-TRUTH LAW (the multi-billion-dollar move)**: profiles stay
  local but resist manipulation through the device's special ID (the
  device anchor) — "to not make manipulating data too easy or
  semi-impossible anyway" — implemented on BOTH platforms. With no server,
  this is honest local enforcement: the anchor rides the profile, sessions
  broadcast a short anchor hash, and a cloned profile shows up as a GHOST
  (two seats, one anchor).
- **THE SURVIVAL LAW**: profiles do NOT die with the app — "make sure
  profiles do not get lost after app deletion or wiping data, make it like
  those cursed multi-billion-dollar companies tricks for real" — the
  Android `Android/media/<package>/` public mirror + the Windows
  `%USERPROFILE%` mirror (the notify-toast registry trick is the house
  precedent). The newest copy wins; a wiped app re-adopts its own mirror.
- **THE VISIBILITY LAW**: members of one LAN session see each other — the
  multiplayer menu lists the session and every member's profile is
  visitable ("so they can visit each other").
- **THE TWO-OPTION LAW**: the multiplayer button's menu wears exactly two
  options: PROFILE and MULTIPLAYER.

v042 plants this seed (the profile store, the anchor, the mirrors, the
sheets); the platform future harvests it (GOGAProfile/ folders, dev
identities, the push flow).

## THE WORKING AGREEMENT (the owner's own sequencing)

"we are just going to talk about the plans step by step together until we
have something suitable so we do not do refactor over another" — the
platform work does not start as code until the talk produces a shape that
survives. This file is the talk's memory. When a question above gets
answered, it graduates from THE OPEN QUESTIONS into a law — or into a
plans/PLAN_vX.Y.Z.md task list, per the ideas/README rule.

## WHERE THIS SITS (the pointers)

- THE_APP_STORE_QUESTION.md (../brainstorms/) — the v0.2.8 question, the
  ad-split dream, the age ladder + GOGAds archive (§7). The question this
  file answers.
- LAN_MULTIPLAYER.md (same folder) — the LAN system spec, updated with THE
  CROSS-PLATFORM UPDATE (cross-platform sessions + the platform /
  player-count tags).
- The commit archaeology: 70335dcf (the rework + "asset-store trials"),
  81351aca (the windows forge), 0dbc1289 (v0.3.4-3 the windows build),
  805b041a (the great un-windowing), 16db01d7 (the open-source round: MIT +
  0 ads + the windows return), 883ba438 (the first windows test round),
  f85ecbc1 (v041 CI green with the windows zip), 5fb78156 + 27b264a6 (tower
  destroyer + the r2 corrections — the round the reveal landed after).
- The ideas/README table indexes this file as a system doc.
