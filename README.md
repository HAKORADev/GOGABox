# GOGABox

GOGABox is an open-source game box for Android and Windows: one small
application that holds your games, your coins, your saves and your
progress. The app itself contains zero games — every game is a plain
folder that lives beside it, so the box stays light and the games stay
yours.

Licensed under MIT. No ads, no accounts, no tracking, no servers, no
internet features of any kind — LAN multiplayer runs on your own wifi.

## How it works

**The application is the box.** The binary contains the game feed, the
search, the GOGACoin wallet, the achievements, the profile and the LAN
multiplayer — but zero games. Every game is a folder:

```
GOGAs/games/<game-id>/     one folder per game
├── game.json              the game's name and details
├── game.pck               the game itself (the one file the box launches)
└── thumb.png              the tile picture shown in the feed
```

The folder name is the game's id. The name lives in `game.json`. The rest
of the folder belongs to the game — its saves, its data files, whatever it
wants. The box reads two files, launches one, and never checks or polices
anything else.

**Where the folder goes.** On Windows the `GOGAs` folder sits next to
`GOGABox.exe` (the release zip already ships them together — unzip and
run). On Android it sits at `Downloads/GOGAs`. Adding a game is the same
on both: drop the folder in, start the box. Removing a game is deleting
its folder. Sharing a game is sharing the folder.

**Everything the box does, it does offline.** No downloads, no updates to
check, no accounts to reach. The only network traffic GOGABox ever makes
is the LAN multiplayer session you start yourself.

## Repository layout

| path | what |
|---|---|
| `projects/gogabox/` | the application (Godot 4.7) |
| `GOGAs/games/` | the shipping set of games — 31 folders, one per game |
| `developers/` | how to make games for GOGABox, and how to use the coins and the LAN |
| `archive/games_v042/` | the original source archive the games were ported from |
| `tools/` | bootstrap, test runner, the game packer |
| `docs/` | project documentation and planning notes |
| `AGREEMENT.md` | the plain end-user agreement |

## Getting started

### Players

Grab the release for your platform. Windows: unzip, run — the games are
already next to the exe. Android: install the APK, extract the `GOGAs`
zip into `Downloads`, done. The age field in your profile only gates the
play button on age-rated games; everything else in the box is
unrestricted.

### Making a game

Start at `developers/README.md`. The short version: build your game in
Godot 4 as a script that extends the box's `GameBase`, pack it with
`tools/v044_package.py`, and you get a folder you can play, keep or
share. GOGACoins, achievements and LAN seats are optional doors your game
can walk through — or ignore completely.

### Building from source

Ubuntu (24.04 tested) with `curl unzip zip jq python3`:

```bash
git clone https://github.com/HAKORADev/GOGABox.git
cd GOGABox
./tools/bootstrap.sh          # installs JDK 17, Android SDK, Godot 4.7.2 (cached in .cache/)
./tools/test.sh gogabox       # headless integration tests (boots every game)
./build.sh gogabox            # release APKs (arm32 + arm64) into dist/
```

Windows builds run on GitHub Actions for every push: the
`GOGABox-windows` zip artifact carries the exe and the `GOGAs` folder
together, and `GOGAs-official` is the same folder zipped alone for the
Android Downloads placement. The pinned toolchain versions live in
`config/environment.lock`; everything is scripted, so CI and local builds
are identical.

## Contributing

Issues for bugs, pull requests for fixes. Games live as folders — if you
make one that runs in the box, it is a game for the box; how you share it
is up to you.
