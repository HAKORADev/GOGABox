# NATIVE_GAMES.md — non-Godot games in the box (the Steam model)

A native game is a real `.exe` (Windows) or a real `.so` (Android) that
CANNOT run standalone — it requires the running box, exactly like a
Steam game requires Steam. The box launches it (or loads it), the game
talks back over the SDK. A native game run without the box is a dead
file: that is the point.

## The two loadings

| platform | how the box hosts it |
|---|---|
| Windows | the box launches the `.exe` as a CHILD PROCESS and keeps living; the game connects back to the SDK bridge (localhost:31442) |
| Android | the box loads the `.so` IN-PROCESS through the loader seat (the game brings its own engine inside the box's process) |

## The package shape

```jsonc
// inside index.json - "runs"
"runs": {
  "pc":      {"kind": "native", "bin": "game/pc/MyGame.exe",
              "renderer": "forward_plus"},
  "android": {"kind": "native", "bin": "game/android/libmygame.so"}
}
```

The strict validator checks the binary exists; the loader seats it.

## The SDK door — the C ABI

`sdk/native/goga_sdk.h` — pure C, zero engine types, OS-specific on
purpose ("libs/ should be low-level OS-specific rather than
godot-specific so anyone could even link zuma deluxe to work inside
gogabox"):

```c
int  goga_connect(const char *client_id);   // the handshake; 0 = ok
int  goga_coins_balance(void);              // THE ONE WALLET
int  goga_coins_spend(int n);
void goga_coins_earn(int n);
int  goga_save_write(const char *key, const char *data);
int  goga_save_read(const char *key, char *buf, size_t cap);
void goga_toast(const char *msg);
void goga_disconnect(void);
```

The reference client `sdk/native/goga_sdk.c` builds with any C compiler:

```
Linux    gcc -shared -fPIC -O2 -o libgoga_sdk.so goga_sdk.c
Windows  x86_64-w64-mingw32-gcc -shared -O2 -o goga_sdk.dll goga_sdk.c -lws2_32
```

Compiled bridges land in `GOGAs/libs/` — the box's boot scan lists what
is present and nothing breaks when something is absent (the honest libs
law). A native game may also speak the wire directly (the protocol is
documented in SDK.md) and skip the library entirely.

## Scaling ("a game like GTA V — the scale, not the titles")

Nothing in the package format limits size: the pck/binary can be tens of
gigabytes, the files manifest carries them all, the discover downloader
streams file-by-file (resume-friendly), and the native kind gives the
game its own process and its own renderer. The box is a launcher with a
wallet, a store and a LAN — it does not cap what launches through it.

## Porting a third-party game (the honest checklist)

1. The game must be YOURS to ship (you own it, it is licensed for
   redistribution, or it is yours to mod locally — see MODDING.md).
2. Wrap the launch: a thin starter that connects the SDK, then jumps
   into the real game (or link the C ABI inside it).
3. Build the package contract: `index/`, `data/` minimums (real files —
   a moddable config beats a dead one), `save/`, `discover/`.
4. Test through the LOCAL flow (a virtual repo or a plain folder
   import) — the local flow IS the remote flow.

## How the seat runs today (v043 pass 3)

- **PC (Windows)**: the box LAUNCHES the exe as a CHILD PROCESS
  (`game/pc/<bin>` from the index's `runs.pc`), shows its own holding
  screen ("close the game window to return"), and ends the session when
  the process exits. SDK-linked games talk back over the bridge
  (localhost:31442); games that never heard of the box still run — the
  bridge is optional, the launch is not.
- **Android**: the in-process `.so` loader is the NEXT platform round;
  the door refuses honestly today ("the Android native loader lands
  with the next platform round") instead of pretending.

## The one-command packager (tools/v043_native_package.py)

Any folder holding a normal game becomes a `.goga`:

```bash
python3 tools/v043_native_package.py \
  --id gogabox_github-<you>_zuma.deluxe.001_hobbyist \
  --title "ZUMA DELUXE" --tag "the PopCap classic" \
  --bin "game/pc/Zuma.exe" \
  --source <the extracted game folder> \
  --out dist/zuma_deluxe.goga
```

The tool copies the folder WHOLE under `game/pc/`, generates the
contract around it (index + versions ledger + discover page + the data
minimums seeded as real files a modder can wire), and zips the `.goga`.
Import it through the box (IMPORT PACKAGE) or drop the unzipped root
into `GOGAs/games/`.

### A delisted game from archive.org (the Zuma-shaped walkthrough)

1. Find the item (`archive.org/details/<identifier>`) and download its
   zip (many abandoned PC games live there).
2. Extract it — you want the folder with the exe and its data files.
3. Run the packager (above) with `--bin` pointing at the real exe path
   inside that folder.
4. Import the `.goga`, press play: the box launches it as its own
   process, the game's own window, your wallet untouched.
5. THE LAW: keep it PRIVATE unless the game's license lets you
   distribute — a package you upload to a public repo is a
   redistribution, and MODDING.md's line (distribution-you-do-not-own)
   applies to packaged games exactly as it applies to assets.
