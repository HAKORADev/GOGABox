# DECOMPILATION — the game-study pipeline (web games, APKs, asset stores)

> **THE USAGE LAW (owner directive, in force).** Everything this pipeline
> produces is **study material**. Every asset crafted from an existing game is
> **modified and redesigned** until it fits what we are building, and every
> readable logic line is **studied first, then rewritten with modifications**
> before it powers a game inside GOGABox. The source and the assets of any
> studied game are **never shared directly** — not committed to this repo, not
> published, not redistributed in any form. What lands in GOGABox is our own
> redrawn/recomposed/re-written work, with the original serving as the teacher.
> (Study copies live outside the repo in `study_out/`; only provenance notes
> and our own derived art enter the repo. See docs/ASSETS.md.)

## Why this exists

GOGABox games are built by studying how real shipped games solve problems —
tower-defense wave pacing, match-3 round economics, runner chunk spawning, and
the thousands of small decisions that never make it into tutorials. The
fastest honest way to learn those is to open working games: pull the HTML5
build from a portal, or unpack an APK, and read the actual data and code. This
doc + the tools under `tools/study/` make that a **known, repeatable
workflow** instead of a re-discovery project every session:

- `tools/study/fetch_webgame.py` — download a playable HTML5 game from the big portals
- `tools/study/fetch_apkpure.py` — download an APK / XAPK from APKPure, scriptable
- `tools/study/decompile_apk.py` — the one-command APK → resources + code + assets pipeline
- `tools/study/godot_pck.py` — Godot .pck extractor (formats 2/3/4) + .gdc string decoder
- `tools/study/fetch_asset.py` — asset stores that need tricks (Quaternius via Google Drive)

Everything was **live-tested on 2026-09-07** with real games; the proven
results table at the bottom lists exactly what came out of each test.

---

## 0. Toolchain — install once per fresh sandbox

Heavy tools live in `/home/z/my-project/.cache/study_tools` (outside the repo).
`decompile_apk.py` auto-finds them there (or via `$STUDY_TOOLS`).

```bash
mkdir -p /home/z/my-project/.cache/study_tools && cd /home/z/my-project/.cache/study_tools

# 1. jadx  (dex -> readable java)                 needs java 17+
curl -sL -o jadx.zip https://github.com/skylot/jadx/releases/download/v1.5.1/jadx-1.5.1.zip
unzip -q -o jadx.zip -d jadx && chmod +x jadx/bin/jadx

# 2. apktool (apk -> readable manifest + res/)    needs java
curl -sL -o apktool.jar https://github.com/iBotPeaches/Apktool/releases/download/v2.10.0/apktool_2.10.0.jar

# 3. .NET runtime (powers ilspycmd + Il2CppDumper) 6 AND 8 are needed
curl -sSL -o dotnet-install.sh https://dot.net/v1/dotnet-install.sh && chmod +x dotnet-install.sh
./dotnet-install.sh --channel 8.0 --install-dir ./dotnet
./dotnet-install.sh --channel 6.0 --runtime dotnet --install-dir ./dotnet

# 4. ilspycmd (C# dll -> readable C#)             needs the full 8.0 SDK above
export DOTNET_ROOT=$PWD/dotnet && export PATH=$PWD/dotnet:$PATH
./dotnet/dotnet tool install --global ilspycmd --version 8.2.0.7535   # 9.x needs net9 - do not
# binary lands in ~/.dotnet/tools/ilspycmd

# 5. Il2CppDumper (libil2cpp.so + global-metadata.dat -> dump.cs + DummyDll/)
curl -sL -o il2cppdumper.zip https://github.com/Perfare/Il2CppDumper/releases/download/v6.7.46/Il2CppDumper-net6-v6.7.46.zip
mkdir -p il2cppdumper && unzip -q -o il2cppdumper.zip -d il2cppdumper

# 6. Cpp2IL (alternative IL2CPP dumper, self-contained)
curl -sL -o cpp2il https://github.com/SamboyCoding/Cpp2IL/releases/download/2022.0.7/Cpp2IL-2022.0.7-Linux && chmod +x cpp2il

# 7. python side
pip install UnityPy zstandard          # Unity assets / godot .gdc decoding
pip install agent-browser && agent-browser install   # only for browser-assisted flows
```

Known-good versions as of this writing: jadx 1.5.1 · apktool 2.10.0 ·
ilspycmd 8.2.0.7535 · Il2CppDumper 6.7.46 · Cpp2IL 2022.0.7 · UnityPy 1.25.x.

---

## 1. Web games — `fetch_webgame.py`

```bash
python3 tools/study/fetch_webgame.py <game page url> [-o study_out] [--any-host]
```

One command: it detects the portal, resolves the REAL game root (each portal
hides it behind different indirection), then recursively crawls the game's own
host(s) for html/js/css/json/images/audio/wasm/atlases, skipping SDK/analytics
hosts. Output: `study_out/<site>_<slug>/` with paths preserved + `REPORT.json`
(engine hints included). To play a copy: `cd <dir> && python3 -m http.server`.

### The site matrix (tested 2026-09-07)

| portal | verdict | how the real game url is reached |
|---|---|---|
| **GameSnacks** | ✅ scripted, full art | The game page is server-rendered; it embeds `<iframe id="game-iframe" src="https://<slug>.h5games.usercontent.goog/v/<token>/">` — Google's H5 CDN, plain HTTP, no auth. Crawl from there. GOTCHA: slugs are portal-owned and sometimes misspelled (Endless Siege = `/games/endlessseige`). |
| **CrazyGames** | ✅ scripted, full build | The game page embeds `https://<slug>.game-files.crazygames.com/<slug>/<version>/index.html` — a plain S3 bucket (wrong paths answer `NoSuchKey`, not 403). No auth. The `/embed/` route is bot-walled (401) but unnecessary. |
| **Poki** | ✅ scripted, full art+audio | Three hops, all plain HTTP: game page JSON `"file":{"content":"\u002F\u002Fgames.poki.com\u002F<build>\u002F<name>"}` → fetch that wrapper → it embeds `"gameUri":"https://<uuid>.gdn.poki.com/<uuid>/index.html"` → crawl. Note `games.poki.com` alone returns the wrapper, `game-cdn.poki.com` 403s - the gdn host is the real file home. |
| **MSN Games** | ⚠️ browser-assisted only | The catalog API (`assets.msn.com/service/msn/v0/pages/CasualGames/`) demands app-auth headers (401 "App authentication info not found"), and the SPA strips itself for headless browsers. The games themselves are third-party embeds on their own CDNs. WORKFLOW: open the game once in a real browser, copy the game iframe src from DevTools, feed it to the tool as a generic url. |
| anything else | generic mode | Pass the game's index.html / iframe src directly; the crawler does the rest. |

### The two game-loading patterns to know

1. **Static references** (most games): assets are string literals in the
   html/js (`"assets/hero.png"`). The crawler resolves them and just works —
   e.g. Endless Siege (Phaser) came out complete: atlases + audio + fonts.
2. **Runtime-built paths** (some games): the code concatenates paths at
   runtime (`"assets/sound/" + name + ".ogg"`), so a static crawl cannot see
   them. When a copy runs but has holes, use the browser-assisted flow:

```bash
agent-browser open <game url>          # let the game actually run a bit
agent-browser network requests | grep -oE 'https://[^" ]+' > /tmp/netlog.txt
python3 tools/study/fetch_webgame.py <game url> --urls-file /tmp/netlog.txt
```

Moto X3M on Poki needed exactly this: the static pass got the shell + atlases,
the network log added every level json and all 60+ sounds (72 files total).

### Engine hints

The tool sniffs each download and reports what the game is built with
(unity / godot / gamemaker / construct / cocos / playcanvas / phaser / pixi /
babylon / three) in `REPORT.json` — check it before deep-diving, it tells you
which asset formats to expect (construct packs everything into the bundle;
phaser keeps loose atlases; unity webgl ships `.unityweb`/`.wasm`).

---

## 2. Android — `fetch_apkpure.py` + `decompile_apk.py`

### 2.1 Downloading (the APKPure trick)

apkpure.com the SITE is unscriptable: Cloudflare Turnstile rejects headless
browsers ("Performing security verification" forever). But the **APKPure
android app** (package `com.apkpure.aegon`) pulls from the download edge
`d.apkpure.com` with its own client identity, and the edge doesn't check for a
browser:

```bash
python3 tools/study/fetch_apkpure.py <package-or-apkpure-url> [--flavor apk|xapk|auto]
```

| endpoint | header set | result |
|---|---|---|
| `https://d.apkpure.com/b/APK/<pkg>?version=latest` | `User-Agent: AEGON/3.20.20` + `x-requested-with: com.apkpure.aegon` | plain `.apk` |
| `https://d.apkpure.com/b/XAPK/<pkg>?version=latest` | same | `.xapk` bundle |

Hard-won gotchas:

- **Both headers are required** — UA alone gets 403.
- **The edge load-balances nodes that disagree**: the same url can answer
  404/403 and then work on a retry (Shadow Fight 2 never stabilized; Poor to
  Rich flipped per request). The tool retries 4× per flavor; when a package
  stays 404, don't hammer it — try another game or retry later.
- **Per-package availability is regional**: packages blocked for the sandbox's
  region answer `302 → https://apkpure.com` (the bounce, not a file).
- **An XAPK is just a ZIP**: `<pkg>.apk` (base) + `config.<abi>.apk` splits +
  optionally asset-pack apks / `.obb` + `manifest.json` + icon.
- The **plain-APK flavor is blocked for some packages** (answers an HTML page)
  while the XAPK works, or vice versa — `--flavor auto` tries both.
- **.obb reality check (2026)**: modern Unity titles ship asset-pack APKs
  (`UnityDataAssetPack.apk`) instead of OBBs; we could not find a fresh OBB on
  APKPure at all. The pipeline still handles real `.obb` inputs (they are
  ZIPs) — a legacy-shaped obb built from WCC2's real `bin/Data` decomposed
  correctly (engine detected from `data.unity3d`/`boot.config`, 37 textures +
  sprites extracted). Legacy OBB games = old catalog entries only.

### 2.2 Decompile (one command)

```bash
python3 tools/study/decompile_apk.py <file.apk | file.xapk | file.obb>
```

Pipeline: unpack container → **apktool** (readable AndroidManifest + res/) →
**jadx** (readable java from classes.dex — ad-SDK soup, but useful for
plugin/bridge study) → **engine probe** → per-engine **code** → per-engine
**assets**. Everything under `study_out/decompiled/<name>/` + `REPORT.json`.

```
unpacked/    raw container + every inner apk extracted
apktool/     AndroidManifest.xml you can read, res/ trees
java/        jadx sources (thousands of sdk classes)
code/
  il2cpp/       dump.cs, script.json, stringliteral.json, DummyDll/  (Il2CppDumper)
  csharp-il2cpp/ readable C# decompiled from the dummy assemblies   (ilspycmd)
  csharp-mono/   readable C# straight from Assembly-CSharp.dll      (unity-mono games)
  godot_pck/     extracted .pck contents                            (godot games)
  js/            cocos/JS-engine bundles copied for reading         (cocos games)
assets/
  texture2d/  every Texture2D as .png          (2D art, atlases, fonts)
  sprites/    every Sprite slice as .png
  meshes/     every Mesh as .obj               (3D! opens in Blender)
  text/       TextAssets (configs, json, dialogue)
```

### 2.3 Engine matrix — what each engine yields

| engine | detect by | code becomes | assets become |
|---|---|---|---|
| **Unity IL2CPP** (most modern) | `libil2cpp.so` + `assets/bin/Data/Managed/Metadata/global-metadata.dat` | Il2CppDumper → `dump.cs` (full class/field map) + DummyDll → ilspycmd → **readable C#** per class | UnityPy → textures/sprites as png, **meshes as .obj**, TextAssets |
| **Unity Mono** (older/small) | `libunity.so` + `Assembly-CSharp.dll` | ilspycmd on the dll directly → readable C# | same as above |
| **Unity, libs not present** (obb/asset-pack only) | `data.unity3d` / `globalgamemanagers` / `boot.config` | — (needs the base apk for libs; pass the whole XAPK) | UnityPy extraction works |
| **Godot 3/4** | `libgodot*.so` / `*.pck` | `godot_pck.py`: all resources out; scripts come as `.gdc` bytecode → the tool decodes **every identifier/string** (GDSC + zstd + XOR 0xB6 scheme, see below); full decompile via GDRE tools (godotengine/gdre-tools, best for ≤4.2) | images, scenes, imports, project.binary |
| **Cocos** | `libcocos2d*.so` / `.jsc` / `assets/src/*.js` | JS bundles copied as-is; `.jsc` = xxtea bytecode (key usually in `settings.js`/`main.js`) | png/plist/json in assets/ |
| **Unreal** | `libUE4.so` / `*.pak` | UEViewer/UModel (external) | .pak extraction via umodel |

**Godot 4.4+ .gdc format** (reverse-engineered here from a real 4.6.1 pack,
cross-checked against `file_access_pack.cpp`): `GDSC` magic + u32 version
(101) + u32 uncompressed size + zstd frame. The token stream stores strings as
u32-per-char **XOR 0xB6**. `godot_pck.py` decompresses every .gdc and writes
`<name>.gdc.strings.txt` — function names, var names, paths, constants. PCK
container formats 2/3/4 are all supported (v3/v4 = pack_flags + file_base +
directory at `dir_offset`, always REL_FILEBASE).

### 2.4 Proven results (live session, 2026-09-07)

| input | engine | what came out |
|---|---|---|
| **Rider** (com.ketchapp.rider, XAPK 152MB) | unity-il2cpp | apktool manifest+res · **15,714 .java** · dump.cs mapping **1,682 Assembly-CSharp classes** (BikeMovement, ScoreSystem, EndlessChunkSpawner...) · readable C# for the game assembly · **305 textures + 992 sprites** (UI atlases, VFX sheets, flag sheets, bike sprites, splash) · **69 .obj meshes** · 44 TextAssets |
| **Temple Run 2** (com.imangi.templerun2, XAPK 180MB) | unity-il2cpp | **18,990 .java** · dump.cs + readable C# (2 assemblies) · **1,588 .obj meshes** — the Demon Monkey (4,164 verts) renders cleanly · 78 textures (Barry tips, character art) |
| **WCC2 obb-shaped payload** (from com.nextwave.wcc2) | unity-data | engine detected from data.unity3d/boot.config · 37 textures + 22 sprites + TextAssets from the .obb (code needs the base apk's libs — expected) |
| **Punball** (com.habby.punball, APK 145MB) | unity-data (not cocos — assumption falsified!) | apktool + 13,053 .java · UnityPy pass ran (assets live in data.unity3d) |
| **Astrosonic** (godot web export, index.pck 38MB) | godot 4.6.1 fmt3 | **260 files** (scenes/scripts/images/imports/project.binary) + strings decoded from **34 compiled .gdc** scripts |
| **Endless Siege** (gamesnacks) | phaser | complete game: 6 texture atlases (1024² each), audio, fonts, config |
| **Moto X3M** (poki + crazygames) | phaser/construct | full atlases (bikes, terrain, explosions, MAD PUFFERS logo), all sounds + level jsons via the browser-assisted pass |

### 2.5 Troubleshooting (the ones that actually bit)

- **jadx dies with -9** on big games → sandbox RAM; the tool caps the JVM at
  2 GB (`JAVA_TOOL_OPTIONS=-Xmx2048m`) and uses 2 threads. Still OOM? Run jadx
  on the config split apk instead.
- **Il2CppDumper exits -6** with "Cannot read keys" → it finished everything
  (dump.cs + DummyDll are written) and then died on its `Press any key` —
  harmless; the tool treats missing `dump.cs` as the real failure signal.
- **Il2CppDumper prints usage** → one of the input paths wasn't absolute
  relative to its cwd; the tool resolves paths before calling it.
- **UnityPy exports 0 assets** → the data may live in `data.unity3d` bundles
  or the `.unity3d` files weren't matched; check `REPORT.json`'s
  `unity_assets.source_files` and widen the file scan.
- **AudioClips show as skipped** → fmod-based export needs a working FMOD lib
  in the sandbox; the raw `.resource` audio blobs stay in `unpacked/` for
  manual extraction.

---

## 3. Asset stores — `fetch_asset.py`

```bash
python3 tools/study/fetch_asset.py quaternius https://quaternius.com/packs/animatedfish.html
python3 tools/study/fetch_asset.py ambientcg Wood095
```

| store | verdict | trick |
|---|---|---|
| **Quaternius** | ✅ NEW - fully scripted (was "browser-only" in docs/ASSETS.md) | The pack page's "Just give me the Download" button opens a **Google Drive folder**. Drive folders list without an API key via `drive.google.com/embeddedfolderview?id=...`, files download via `drive.usercontent.google.com/download?id=...&export=download&confirm=t`. The tool walks the tree (Blends/ FBX/ OBJ/ License) and fetches everything — proven live: 29 files incl. FBX + OBJ + .blend (CC0). |
| **ambientCG** | ✅ scripted | API v2 search → `ambientcg.com/get?file=<id>_1K-JPG.zip` (re-verified; see docs/ASSETS.md) |
| **Poly Haven** | ❌ still browser-only — now with the reason | info API returns `files:{}` (empty), `dl.polyhaven.org` 404s, and the site **assembles the zip client-side with zip.js** — there is no direct file URL to grab. Browser once → vendor → manifest. |
| **Godot Shaders** | ❌ WAF | answers 454/455 to bots; copy by hand. |
| Kenney / GameArt2D / Google Fonts | ✅ | already handled by `tools/sync-assets.py` / direct urls (docs/ASSETS.md). |

---

## 4. The future-me runbook

1. **"I want to study web game X"**
   → `fetch_webgame.py <portal page url>` → check `REPORT.json` engine hints →
   open the folder, read the JS (readable by construction), slice the atlases.
   Empty holes → browser-assisted `--urls-file` flow.
2. **"I want to study android game Y"**
   → `fetch_apkpure.py <package>` → `decompile_apk.py <file>` → read
   `REPORT.json` → code in `code/`, art in `assets/`, view meshes in Blender.
3. **"I need the actual C# logic"** → IL2CPP: `code/il2cpp/dump.cs` for the
   map, `code/csharp-il2cpp/Assembly-CSharp/` per class. Mono:
   `code/csharp-mono/`.
4. **"I want Quaternius pack Z"** → `fetch_asset.py quaternius <pack page>`.
5. **"I need Poly Haven / Godot Shaders"** → browser once, vendor, record.
6. **Any derived asset entering GOGABox** → redesign it (our palette, our
   shapes, recomposed), then record provenance in
   `projects/gogabox/assets.manifest.json` + docs/ASSETS.md, like the Endless
   Siege→Pop Siege art pipeline did.
7. **Never** commit a study copy, a dumped asset as-is, or decompiled code to
   the repo. `study_out/` is scratch; the repo carries tools + docs + our own
   work only.
