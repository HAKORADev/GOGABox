# PLAN_v044 — the box, simplified

The owner tested the v043 build, then made the big call: **roll the platform
back, not the games**. GOGABox stays a Godot-only game box. Everything that
made it an app store — discover, downloads, updates, packages, web/native
runners, community CI — is removed. What stays: the games, the economy, the
profile, the LAN, the age door. This is v044 (a real version bump, the owner's
call), and it is the last big shape change of this project.

## The owner's order (verbatim anchors)

> first, we should not support web or native games, we should keep it godot
> only / second, we should not make a discover or github-backed infra for
> GOGABox / ... even LAN should be removed? orrr....keep it? i guess keep it
> ok / try to somehow roll the things back accurately normally, games must
> remain out of binary, GOGAs/ should be main folder for games and it should
> contain a folder for each game and a game should be as it wants to be, but
> the entry should be one unified name so the engine knows where to look at,
> also folder is just id while game name in a file / no importin, no
> downloading, no internet updates and...nothing / just make games out of
> binary, keep the fixes happened during the work, fix the games structure so
> they work accurately without crashing, current games like dominoes and
> fruit slasher are crashing while ping pong is not / let the content and age
> rating and these things, no CI/CD or community work, but people still can
> make games that runs in GOGABox / also currently a one-platform game still
> appears in the other platform but pressing play does not run it, a better
> way is to make the button say "phone only / pc only" / try to port other
> games and make sure they will keep running / update the repo docs and the
> project code and tools and the whole view, make this as v044 / still we
> need the "developers" side so agents and other people know how to make
> games here and how to use the GOGACoins or the LAN if they want to / also
> no need to make imports/exports or .goga / .gogas files, users can just
> take a game folder and put it in-place, the game entry will be launched,
> the game code itself will manage where the files are and like that without
> any GOGABox-side observation, sharing and creating will remain the same,
> but not managed by "us" / still no feature will be lost this way, just the
> extra things that are not good to be in a "GOGABox" as what i see / also in
> LAN, remove vLAN and keep the normal local multiplayer, remove the AISlop
> extra text in the app menus that feels weird and non-professional / the
> binary stay small, you ship games outside binary, you keep GOGAs/ in the
> repo but for another purpose now

## 1. THE GAME FOLDER (the one format)

    GOGAs/games/<id>/      the folder name IS the game id ("domino")
      game.json            the name file - the display name + the registry
                           vocabulary (title, desc, os, age, content, genres,
                           fee, price, shop, reveal, lan, ach, controls...)
      game.pck             THE UNIFIED ENTRY - every game's pack wears this
                           one name; the engine mounts it and loads the
                           script game.json points at
      thumb.png            the tile art (game.json "thumb": "thumb.png")
      anything else        the game's own business - saves, data files,
                           docs - the box never looks, never polices

Rules:
- **Folder = id.** No id scheme, no tiers, no package ids, no renaming law.
- **game.json = the name file.** No title in the folder name anywhere.
- **game.pck = the one entry.** One pack per game (pure-GDScript 2D packs
  are platform-neutral - one build runs on both platforms).
- **No validation.** The scanner reads two files; a folder without them is
  not a game, and nothing else is refused, scored, or mandated. No data/
  minimums, no save/ contract, no versions ledger, no discover material.
- **No zips.** .goga / .gogas die. Sharing a game = sharing a folder.
- The SDK doors stay OPTIONAL: GOGA.coins_*/save_*/data_*/visual_override
  still work for games that want the economy or a save spot inside their own
  folder. Games that ignore them are equally welcome.

## 2. What is removed from the engine

| removed | was |
|---|---|
| `goga_discover.gd` + the whole discover seat | the github-backed feed, tiers, sources, catalog, download, import dialog |
| `goga_update.gd` + the boot check + the updates sheet | the self-update channel |
| `goga_webserve.gd` + `goga_runner.gd` web door + the gogabrowser plugin | the in-app web game seat |
| `goga_runner.gd` native door | the PC child-process native seat |
| the TCP bridge (31442) + the WebSocket bridge (31443) | the standalone-game SDK transports |
| the importer (.goga/.gogas/folder import, IMPORT PACKAGE, ADD SOURCE) | the package install path |
| `GOGAs/discover/` + `GOGAs/libs/` + `GOGAs/.cache/` from the home tree | the store material |
| `sdk/` (native C ABI, web JS, the Godot plugin) | the multi-transport SDK |
| the community CI (goga-registry.yml, goga-packages.yml), REPORTING.md + issue templates | the community machinery |

Kept whole: the GOGAs home law (Windows next to the exe, Android in
Downloads, dev override), the unified entries law (GameReg.games()), the
mount law (replace_files=false), the SDK doors, the age door + content tags
+ the chip law, the boot design law, the GOGAs delivery with the artifacts,
the LAN stack (minus vLAN), the economy, the profile, the roadmap.

## 3. LAN keeps the local half

- KEPT: the whole session core (host truth, seats, holds, relays, chat,
  voice, faces, locks, declines, the waiting room, the profile), the UDP
  discovery on the wifi, direct LAN play.
- REMOVED (the vLAN / online leg): the UPnP + NAT-PMP + PCP mapping stack,
  the room-code encoder/decoder, the ONLINE box in the LAN sheet, the
  ONLINE ON/OFF states, the public-address logic. Local multiplayer only.

## 4. The play button tells the truth

A game whose game.json `os` does not include this device shows the button
**PHONE ONLY** or **PC ONLY** - disabled, honest, one word pair. No more
"press play and nothing happens".

## 5. The ports (all of them)

Every v042 game returns as a game folder - 31 games:

bovo, brickbreaker, chess, cosmic_spud, dario, deathworm, domino, fourline,
geometry, goldminer, heavywar, hopper, invaders, jumpcube, lanes, ludo,
marble, matcher, maze, merge, pacman, pop_siege, rally, rockbreaker, slasher,
snake, snl, squares, towerball, towerdestroyer, xo

- Source of truth: `archive/games_v042/` (scripts, per-game assets, thumbs,
  the exact registry entries, the archived game audio).
- The packer (`tools/v044_package.py`) stages the box core + the game's
  scripts and assets at their original res paths, imports, exports ONE
  `game.pck`, and writes `game.json` + `thumb.png` beside it.
- Each pack carries the game's own music + sfx (scanned from the game's
  scripts; the Jukebox resolves mounted-pack audio at call time).
- Platform truth from the v043 pilot list: domino = PC only, jumpcube =
  Android only, everything else = both.
- Age + content: the v043 pilot ages (rally 7, slasher 7) kept; every other
  game ships age 3 / no content tags unless its own nature says otherwise.
- GOGA ORBIT (the web pilot) is removed whole - web games are gone.

The crash hunt: the v043 pilots ran their BAKED twins (the loose copies
shadowed the packs - law 110 cuts both ways). v044 makes the shadow
impossible: the binary carries zero game code, every game runs from its own
pack, and flow_test boots **every single game** headless - the battery is
the crash gate, not a hope.

## 6. The texts

The app menus lose the helper-speak. Every long honesty wall, the store
hints, the empty-home lecture: rewritten short or removed. The menus should
read like a person wrote them - labels and one-line helps, nothing else.

## 7. Delivery

Unchanged from the v043 fix (it worked): the Windows zip carries `GOGAs/`
beside the exe; the Android artifacts ship `GOGAs-official-*.zip` for
Downloads extraction; the release body carries the placement line. The
repo's `GOGAs/games/` tree IS the shipping set of games now - build CI
copies it into the artifacts as-is.

## 8. The gates

1. `tools/test.sh gogabox` (flow_test): the new folder scan, the platform
   labels, the age door, the economy - and a boot pass through **all 31
   games** from GOGAs/.
2. `qa_v042_lan`: the loopback rig minus the online leg.
3. `parse_gate`: every script clean.
4. The eye pass: the feed, the pre-play page (PHONE ONLY visible), the
   settings sheet without the updates seat.
5. CI green on both platforms; the Windows exe small (no game bytes inside).
