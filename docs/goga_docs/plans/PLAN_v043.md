# PLAN v043 — THE PLATFORM ROUND (GOGABox stops being a box of games and becomes the platform the games come to)

> The owner's work order, 2026-09-27 (v042-1 r4 shipped the same day). Two
> halves, one round: **the age system returns, simplified** (the app-store
> question, third appearance) and **the platform split** (THE_PLATFORM_ANSWER.md
> graduates from document to engine). The owner's own framing: "i will not
> test this build directly, i will just let you work on it accurately and
> take your time on it" + "take your time doing your work in the infra
> itself because we will need it later". No version bump beyond 0.4.3
> (the patch naming law: 0.4.2-4 → 0.4.3, code base +10).

## THE OWNER'S ORDER, DECOMPOSED (every line mapped)

### HALF A — THE AGE SYSTEM (from THE_APP_STORE_QUESTION.md §7, simplified)

| # | the order (verbatim anchor) | the law that ships |
|---|---|---|
| A1 | "rename 'more tags' to 'sub genres'" | the search sheet + pre-play + guide rows retitle; the SUB key is the same |
| A2 | "add them from 3 to +21 and re-add the age tags in pre-play and per-game and in the search" | Meta.AGES ladder (3/5/7/9/12/16/18/21, the archive's own tier texts), the AGE chip row in search, the AGE section on the pre-play page + guide |
| A3 | "the age system will be simplified, a game can be discovered, downloaded, owned and everything by people under the age, but the button 'play nn goga_coins_icon' in the pre-play will just gray-out and say you must be +nn" | THE AGE DOOR LAW: age touches ONLY the play button. Nothing hides. The disabled button reads "YOU MUST BE +NN"; the why-label carries the tier name |
| A4 | "it will detect this by the profile age number only, if number is not set, it will open games up to +12 and the rest will say same message with the lock" | THE PROFILE AGE LAW: LanProfile.age() (0 = unset → the +12 ceiling: ages ≤ 12 play, 16+ lock) |
| A5 | "genres, searching, downloading, everything else will work normally" | no other gate reads age. Ever. |
| A6 | "content tags... horror, gambling, politics, porn, psycho, and many other content" (the owner forgot the exact list; the archive §7.1 carries it) | Meta.CONTENT: horror, psycho, gore, porn, gambling, politics, illegal_trading, nudity — built from the archive's tier texts (porn, gore, gambling, intense horror, political-sensitive, psychological-intense, nudity, illegal trading) + the owner's two adds (politics, psycho). Chip row in search + sections on the pages |
| A7 | "in-game genre/sub-genre tags should be case-insensitive i mean if someone wrote BOarD or boARd, all will lead to same genre/sub-genre" | THE LOWERCASE LAW: every genre/sub/content id normalizes to_lower() at READ time (Meta.normalized), so mixed-case data from any package joins the same chip |
| A8 | "add a feature in the search engine of GOGABox to index games genres/sub-genres to detect unsupported keywords, when there is +10 games in the user library have same genre/sub-genre, then index it too" | THE SELF-LEARNING INDEX: Meta.used_* grows past the const tables — a genre/sub not in GENRES/SUBS that ≥10 installed entries share becomes a first-class filter chip (labeled from its own id), persisted in Box meta |
| A9 | "no GOGAds, no agreement 'yet' and these things" | GOGAds stays dead. The agreement lives in the REPO (developers + end-users files, P8) — the app ships no gate screens |

### HALF B — THE PLATFORM SPLIT (THE_PLATFORM_ANSWER.md graduates)

| # | the order | the law that ships |
|---|---|---|
| B1 | "make the GOGAs/ folder now and remove all games from the main binary and make GOGABox itself an app by itself like engine" | THE EMPTY BINARY LAW: registry.GAMES = []. The box ships ZERO games; every game arrives as a GOGA package |
| B2 | "in windows, make the folder next to the exe, in android, make it in the downloads folder" | THE GOGAs HOME LAW: Windows `<exe_dir>/GOGAs/`, Android `/storage/emulated/0/Download/GOGAs/` (MANAGE_EXTERNAL_STORAGE, the honest ask at first use) |
| B3 | "libs/ where the dlls and the sdk main compiled files... and games/... and discover/... and .cache" | the GOGAs tree: `libs/` (SDK bridges), `games/<id>/` (installed packages), `discover/` (the source registry + feed material), `.cache/` (download temp + per-source feed caches) |
| B4 | "a .goga will contain inside it the game folder root, .gogas contains many games where each folder is a game root, folder name itself isn't game name and it will be renamed to match the game id found in the index folder" | THE RENAME LAW: import (.goga zip / .gogas zip / plain folder / parent-of-roots) renames every installed root to its index id. Package roots: `index/` `game/` `discover/` `data/` `save/` (+ optional `src/`) |
| B5 | "a game likely will be published with two different versions one for pc and one for phone....or you figure out" | THE INDEX DECIDES: ONE package carries per-platform game/ builds (`game/android/`, `game/pc/` or a shared build); index.json's platforms map picks by OS at run time. Separate packages per platform also legal |
| B6 | "save the original current games in the repo somewhere" | `archive/games_v042/` — every stripped game script + its assets + registry entries preserved in-repo, one README mapping ids |
| B7 | "develop the full sdk and apis and required dlls for each platform... or developers will anyway use the binary? if you think make the /libs folder just part of the binary and this will be better, than also that's ok" | THE UNIFIED SDK DECISION: the box binary IS the SDK for embedded games (the autoloads = the API). `GOGAs/libs/` exists as the extension point: the native ABI (goga_sdk.h, C), the IPC bridge for standalone Godot games, and the Godot plugin `gogabox_sdk` (the Unity-ads-shaped addon). The loader scans libs/ at boot |
| B8 | "do not forget to make them perfectly so games do not have any hardcoded stuff" | games read their own index + data/ through the GOGA SDK door; zero box paths in game data; shared look (fonts, coin icon, UI kit) comes from the host |
| B9 | "write the developers catalog for the sdk and apis and all functions... in specific folder organized with many md files and main file for referencing and sorting like an index" | `developers/` — indexed catalog (P8) |
| B10 | "develop both .goga and non-zipped game folders so they be manageable by GOGABox, make it even support .goga and .gogas and normal folder selection to import" | the importer eats all three shapes (P3) |
| B11 | "develop the main discover engine with the game page, game files, cache, download, game description and media... also the engine-side handling of data processing like what to cache and what to put here or here" | the discover engine (P5): sources → index fetch (raw HTTP, no API) → feed → page → download → .cache → validate → install; the data-processing map documented |
| B12 | "develop the discover feed as an option can be selected from a right-arrow that will be next to the 'all games' text in main feed to switch between them" | THE FEED SWITCHER: ALL GAMES ⇄ DISCOVER via the arrow beside the headline |
| B13 | "search engine will work on it too but with extra stuff like size+arrow-up... size arrow down... date up/down... version up/down" | the discover search sorts: size/date/versions × ↑↓ + the normal keyword/genre/age/content filters |
| B14 | "develop the update/download stuff in the GOGABox ofc and the schedule" | version compare + boot check + the settings schedule (the interval, auto-download toggle) |
| B15 | "make discover supports github and local where local here means whether a folder or a folder contains many folders in it where a folder can mean a game or a virtual github repo to simulate the process for developers" | THE LOCAL SIMULATION LAW realized: a local source = package folder, parent of roots, OR a "virtual repo" (a folder carrying gogabox.repo.json + game roots — the full github flow, zero network) |
| B16 | "also develop the discover of github repos and the index and the CI/CD infra of official/community/hobbyists too" | tiers hardcoded ENGINE-side: official = the owner's repo (hardcoded list), community = listed in the official REPOS.txt (CI-validated), hobbyist = everything else (manually added sources / imported packages whose ids say so) |
| B17 | "the tricks of updating the app like for android where it uses the android package installer after asking for that permission and windows for replace the file after close and notifying user to close when ready" | P7 |
| B18 | "in the github stuff, you will use the official GOGABox repo as the first official repo in discover so make the folder for it... and the http raw search engine-like queries to not consume all github API rate-limits" | the official source fetches raw.githubusercontent.com ONLY (THE NO-API-LIMIT LAW from the reveal doc) |
| B19 | "the developer profile or the 'share your game' thing... make repo, pull request with your link in the specific file in the specific folder, wait, done" | the two-step publish: PR adds one line to `discover/REPOS.txt`; CI validates the repo's index; merge = community tier |
| B20 | "no developer profile, official/community/hobbyist are not game maker-specific, they are hardcoded in the engine" | tiers live in goga_core.gd engine code; modifying local data only hurts the user's own UX (the owner's own point) |
| B21 | "i do not want you to work on all games, just first port pong and fruit slasher 1:1 for both devices and dominoes for PC only and dice conquer for android only, that's for testing" | the four ports (P6): rally (both), slasher (both), domino (pc), jumpcube = CONQUER DICE (android) — 1:1, from their index, zero hardcoded box paths |

### HALF C — THE SECOND MESSAGE (web games, openness, modding, reports)

| # | the order | the law that ships |
|---|---|---|
| C1 | "make sure that the new games infra will support any game to run in the app, let's say a game like GTA V... but under godot i mean, i am just talking about the scale" | the runner kinds scale: godot_embedded (shared process), native (own process on PC / .so in-process on Android), web (C2) — the index's `kind` field |
| C2 | "godot supports HTML5 so make it even support it's games and HTML5 web games to run in the app with no pop-up browser tabs... there is two things, godot as HTML5 game and real .html and web games like made with three.js" | THE WEB KIND: game/web/ carries an entry .html (+ its files). Android: an in-app WebView surface (the gogabrowser plugin — JavascriptInterface bridge, never an external tab). PC: the WebView2 slot (honest absence note until the extension lands) |
| C3 | "support the bare web games too, no native games... that works as standalone, as same as steam api where it forces the steam app to launch... so i guess you will likely need the libs/ folder at the end so external games could use it? that's complex...for me! but i guess you know the best" | native kind = REQUIRES THE BOX (the Steam model): PC .exe child-process + SDK IPC; Android .so in-process. libs/ carries the C ABI the native game links. A native game run without the box is just a dead file |
| C4 | "libs/ should be low-level OS-specific rather than godot-specific so anyone could even link zuma deluxe" | goga_sdk.h: pure C, no Godot types — connect/coins/save/achieve/lan/toast/quit over the localhost IPC socket |
| C5 | "make the catalog for the agents and human developers to be 'open' so making games be also 'open'... data/ folder contains many plain .json logic code inside /logic and an /audio contains /voice /sfx /music and /visuals contains /characters /assets /vfx /shaders" | THE OPEN DATA LAW: data/logic/ (plain .json), data/audio/{voice,sfx,music}/, data/visuals/{characters,assets,vfx,shaders}/ — the strict minimum set the validator demands |
| C6 | "tell developers to share src/ in the .goga or with the game bundles for more modification and community remixes" | src/ = optional-but-preached; the catalog says it, the validator waves it through |
| C7 | "try to make engine work with very strict rules so it do not accept importing or downloading a game that do not have /data with exposed files and populated stuff with minimum level like at least it has the sfx, music, shaders, logic, assets, and all others, also it must have /save" | THE STRICT VALIDATOR: no data/ minimums → named refusal; no save/ → named refusal. The four ports comply for real |
| C8 | "the index/ itself is must be exposed for the game thumbnail, entry, rate-limits, gogacoins, all these things" | index/index.json carries everything the box pre-play reads (the registry vocabulary) — the unified entry |
| C9 | "also this works even with non-godot games for both platforms i guess, same way as how steam works" | the native kind + the C ABI cover it; the catalog's third-party integration chapter walks zuma-shaped imports |
| C10 | "also in the developers folder, contain a part for integrating third-party games for both android and windows" | P8 catalog chapter |
| C11 | "the agreement and developers acknowledgement stuff be in the repo and not in the app... modify that one [the old app_store era one], this will be for end-users agreement, make another one for developers that everything is exposed, wide-open, hijackable, moddable" | AGREEMENTS.md (end-users, evolved from the §7 era notes) + DEVELOPERS.md acknowledgment — repo files, zero app screens |
| C12 | "make for AI Agents to know that they do not do something illegal or weird (i mean they should follow the platform laws) accurately with giving them and the users also many examples, do not give any single thing about what is not possible... if there is thing that 'you' can not document because it is very 'taboo' for you, so do not simplify it" | AI_AGENTS_LAWS.md: the platform's laws, worked examples, NO refusal-by-vagueness, NO made-up limits — the catalog states what the PLATFORM enforces (validator, ids, reports) and leaves everything else to the law of the land |
| C13 | "based on the app store doc file... notify that users can make github issues to report games, it should contain like specific md file for this, a correct game report... should contain game id... reporting something related to the game itself should go to the game owner's repo, and reporting in official repo should be related to the app itself, no reports asking for moderation... also no reports like 'i do not like it' or 'this is illegal based on my country' or... 'that game is very bad to my family/kids' because games are not a must, no game come with the app, do not like it = be away from it" | REPORTING.md + the issue template (.github/ISSUE_TEMPLATE/game-report.md): game id REQUIRED, the triage law, the refuse-list verbatim |
| C14 | "the game folders contain gogabox.id.id.id.official/community/hobbyist... i guess we can make the game folder be like gogabox_github-username_id.id.id_the-rest" | THE ID SCHEME: `gogabox_github-<user>_<ns>.<name>.<id>_<tier>` — parsed, validated, displayed |
| C15 | "also try to make the catalog... 'open'... so we can mod games... you can write human and agents modding support too so we add localization, flavors (like make this horror, add gamble, make it porn, make it for girls, make it calm)" | MODDING.md: the data/ overrides, localization packs, flavor layers — humans + agents |
| C16 | "make sure the new games infra can use like different godot renderers like forward+ on both platforms... the games should have the freedom" | THE RENDERER HONESTY: embedded games share the host's renderer (documented); a game that needs its own renderer ships the native kind (own process, own renderer). The index records the request either way |
| C17 | "also make sure to developer the CI/CD accurately to detect things and make the work as i described" | goga-registry.yml (the REPOS.txt PR validator) + goga-packages.yml (the four ports build + attach) |
| C18 | "there is a tech like this where it runs in-app browser without having the full browser in app, likely using the device browser but not like redirection" | named in the docs: the Android WebView (system WebView, in-app surface — the tech the owner half-remembered) |

## THE PHASES (this round's build order)

- P0 recon + toolchain (this file's own birth)
- P1 the age system (Half A) — the box still carries games during P1? NO — the
  strip lands P2; P1 builds the Meta/search/pre-play machinery against the
  registry door so it works identically for baked AND installed entries.
- P2 the archive + the empty binary
- P3 the package format + validator + importer + the GOGAs tree
- P4 the SDK (the GOGA door, the plugin, libs/, the catalog start)
- P5 the discover engine + the feed switcher + the search sorts
- P6 the runner + the four ports + the in-box boot proof
- P7 the app self-update tricks
- P8 the developers catalog + agreements + reporting + CI/CD + the repo docs refactor
- P9 0.4.3, the full battery, the eye passes, push

## THE TESTS (the owner is NOT testing this round — the rig is)

- flow_test: rewritten for the empty binary + the four installed packages
  (every port boots, runs, banks — from its package, not from a baked entry)
- qa_goga: the validator's refusals (each named error), the import shapes
  (.goga/.gogas/folder/parent), the rename law, the id scheme, the strict
  data minimums, the age door, the self-learning index
- qa_discover: the local source full loop (feed → page → download → install →
  play), the virtual-repo simulation, the REAL github raw loop against this
  repo (sandbox has internet), the search sorts, the update version compare
- qa_v042_lan: must stay green (the LAN round's regression shield)
- eye passes under Xvfb: the feed switcher, the discover page, the pre-play
  age states (locked +12-unset, locked +16, open)

## THE DECISIONS TAKEN (the owner delegated these — recorded)

1. **libs/ = part of the binary** (B7): the owner offered the choice; unified
   wins — the box's own autoloads ARE the SDK for embedded games, and
   GOGAs/libs/ stays the drop-in point for the native bridges (C ABI + the
   IPC bridge for standalone games). Nothing duplicated per game.
2. **ONE package, per-platform builds** (B5): a package carries
   game/android/ + game/pc/ when the builds differ; the index picks. A
   package with ONE shared build (pure GDScript) also legal. Platform
   exclusives = the platforms map carries one entry (domino: pc only,
   conquer dice: android only).
3. **The tier model** (B16/B20): official = the hardcoded repo list;
   community = REPOS.txt (CI-verified); hobbyist = everything else. The
   folder id suffix declares the tier; the engine trusts the suffix of
   imports but the DISCOVER tier comes from the source that served it.
4. **The web runner**: Android ships the real in-app WebView (the
   gogabrowser plugin, JavascriptInterface = the SDK bridge for web games —
   window.GOGA.*). PC ships the WebView2 slot honestly (the discover page
   says "PC web support lands with the WebView2 extension" until it's real).
5. **DLC-era pck law**: load_resource_pack(replace_files=false) — the box's
   own files can never be shadowed by a package; the packaging projects
   stage the box core at the SAME res:// paths so a package's compiled base
   class references resolve to the box's real classes at runtime.
6. **"Dice conquer"** = CONQUER DICE = machine id `jumpcube` (the owner's own
   rename, docs/goga_docs/gogames_ideas/jumpcube.md).

## PASS 2 — THE REAL STRIP (the owner's catches, worked to the bone)

The owner reviewed the first v043 push and caught three things: the main
binary "stayed same size", a build failed before the finished one, and the
rewritten docs read like slop ("What GOGABox is (the v043 platform
shape)"). All three were real.

**The size catch — the empty binary was not empty.** `GAMES := []`
stopped referencing the baked games but left every file in place, and the
export packs everything not excluded: `game/games/` (35 folders),
`assets/games/` (42 MB), `assets/audio` game music+sfx (43 MB), game
thumbs (5.6 MB) still rode the APK/exe. Worse — the packaging rig stages
the game script at the SAME `res://game/games/<id>/` path inside the pck,
and the box mounts with `replace_files=false`, so the box's stale loose
copy SHADOWED the packaged port: the pilots ran their baked twins, not
the packages. The strip (`tools/v043_strip_binary.py`, idempotent):

- archived the forgotten game audio (585 files → `archive/games_v042/audio/`)
  + the 135 dead-path test probes (→ `archive/games_v042/probes/`)
- deleted `game/games/` + `assets/games/`, trimmed `assets/audio` to the
  box-owned keep-set (ui/, notify/, jingles/, box_theme.mp3,
  boom/coin/unlock.ogg) and `assets/thumbs/` to soon.png
- `projects/gogabox`: 192.8 → 112.8 MB on disk (the .godot import cache is
  most of the rest and never ships); the packed payload is the engine +
  the store only
- export presets exclude `tests/*` from every build

**The failed build — goga-packages.** The workflow's validator demands
`save/` in every committed package; the packaging rig creates `save/`
empty and git cannot commit an empty folder, so the pushed tree read as
broken while the local one was fine. Fixed at three layers: every
committed package carries `save/README.md` (the law's text AND the law's
proof), the rig writes it on every assemble, and the importer re-seats
`save/` on the FOLDER import path too (the transport-artifact law — git
and zip-less shares lose empty folders exactly like zips do; `data/`
minimums stay strict). `tools/goga_ci_validate.py tree` → ALL VALID.

**The destructive-import catch (the rig's own).** `_import_root` MOVED
the source root into `games/` — the flow test installs the repo's own
`GOGAs/games`, so every test run ate the committed packages out of the
working copy (and a developer's virtual-repo source would suffer the
same). THE NON-DESTRUCTIVE IMPORT LAW: installs COPY, never move; the
source survives untouched.

**The docs.** README rewritten as a plain professional front door (what
the platform is, how packages work, repo map, quickstart, publishing) —
no version-anchored headers, no law-jargon walls; AGREEMENT.md intro
de-changelogged. The law-speak stays where it belongs (AGENTS.md, the
developers catalog, the engine comments).

## PASS 3 — THE PLATFORM CORRECTNESS ROUND (the owner's Windows test round)

The owner tested the pass-2 build on Windows and came back with a list:
the discover arrow did nothing, the boot mis-scaled (horizontal window,
vertical content), the GOGAs tree shipped empty beside nothing, the
search chips behaved the opposite of his words, the GOGAs infra was
"simplified... will never survive one real-life work", the updates menu
was not the plan's, and the runner kinds (web/native) had never actually
existed. His own framing: "make this as another round and not a
version/patch pump" - the config stays 0.4.3.

**The dead arrow (the tappable re-seat law, 127).** The switcher arrow
was a real Button inside the feed BoxScroll, and the scroll owns every
press (the mouse is swallowed in `_mouse()`, the touch in `_owns()`) -
every other discover control was a registered tappable, the arrow never
was, and the flow test called `_toggle_feed_kind()` directly, masking
it. Worse: `_refresh()` CLEARS the tappables, so even a correct
registration at build time died on the first rebuild. The arrow now
re-seats on every refresh, and the eye pass clicks it through the REAL
input stack (parse_input_event + the emulated-touch twin - the r4
window-px law).

**The boot mis-scale (the design-first boot law, 128).** F10 is
design-first (apply_pc, then the window); boot was window-first - the
design only landed in menu._ready, after the splash beat, and the
menu's own flip never triggered a reflow (the governor's compare saw no
change). Boot now walks the F10 order and the eye pass proves it: the
persisted landscape choice renders the landscape design from the first
frame, the grid reflows, nothing letterboxes.

**The chips (the chip law, 129).** The owner's clarification verbatim:
hardcoded tags always show; unknown tags appear only at >= 10 owned
games. The old rows used used_* (any count, no hardcoded table). The
rows now open with the const tables, the census covers content tags
too, and the age chips wear the words ("+12 YOUNG TEENS", "+21 ADULT
ONLY" - the archive's own tier texts).

**The catalog (the catalog law, 130).** GOGAs/discover/index/ was ONE
file. Schema 2: source.json (the identity + the tier file map) +
official.json / community.json / hobbyist.json, REPOS.txt unchanged as
the PR register, CI keeping community.json in lockstep. The tier trust
law: official-source rows wear the file's name, everyone else wears the
engine's tier. Local sources walk the same catalog when repo-shaped
(repo root or the GOGAs folder itself). Per package: index/versions.json
(the ledger law, 131) - the VERSIONS sort reads real data, the
validator and CI demand it.

**The runner doors (the runner doors + one-bridge laws, 132-133).**
mount_for returned false for web/native - the launch died silently.
Now: WEB = the box's own loopback static server (GogaWebserve) + the
gogabrowser Android plugin (the system WebView in-activity) / the PC
app-mode window (msedge/chrome --app, the WebView2 runtime, chromeless)
+ sdk/web/goga_bridge.js over the NEW WebSocket door (31443 - same
vocabulary, one dispatcher). NATIVE = the PC child process + exit
watching (the rig compiles a real C stub that rides the TCP bridge and
proves the whole loop); the Android .so loader refuses honestly this
round. THE WEB PILOT SHIPS: GOGA ORBIT (three.js, vendored, bridge-live)
as the fifth official pilot.

**The delivery (the GOGAs delivery law, 134).** The Windows zip now
carries GOGAs/ beside the exe; the Android build uploads
GOGAs-official-*.zip for the Downloads extraction; the release body
carries the placement command; the box notes where the tree goes when
it boots empty.

**The updates sheet (the updates sheet law, 135).** CHECK NOW, the
interval picker (12H/24H/2D/WEEKLY), AUTO-DOWNLOAD (a scheduled find
stages the download; the note names the APPLY tap), and the staged
seat - the plan's whole schedule, not just the census.

**The native packaging tool** (tools/v043_native_package.py): any
folder with a normal game becomes a .goga in one command - the
Zuma-shaped walkthrough lives in developers/NATIVE_GAMES.md. The
archive.org pull could not run from this sandbox (the front door was
unreachable all session); the tool is proven end to end with a
compiled stand-in, the walkthrough is written for the owner's machine.

Gates: flow_test ALL TESTS PASSED (the catalog walk, the webserve, the
WebSocket bridge, the native stub ride it) + qa_v042_lan 177/0 +
parse_gate 90 scripts ALL CLEAN + the CI tree validator ALL VALID + the
eye pass (six shots) reviewed by eye: the landscape boot, the arrow
flip through a real click, the five-pilot catalog feed, the live web
seat (the three.js game rendering in the app-mode window), the rebuilt
updates sheet, the full chip rows.
