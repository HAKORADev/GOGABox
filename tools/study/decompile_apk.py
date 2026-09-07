#!/usr/bin/env python3
"""decompile_apk.py - the one-command APK/XAPK/OBB study pipeline.

    python3 tools/study/decompile_apk.py <file.apk | file.xapk | file.obb> [-o OUTDIR]
        [--no-assets] [--no-code] [--max-assets N]

What it does, in order (everything it can, skipping what a missing tool blocks):

  1. containers    xapk/obb are ZIPs - unpacked first. An xapk yields the base
                   apk + split config apks + manifest.json. An obb yields raw
                   assets. Unity's modern "UnityDataAssetPack.apk" is unpacked
                   like an apk too.
  2. resources     apktool (java) - readable AndroidManifest.xml + res/ tree.
  3. java/kotlin   jadx - readable .java sources from classes*.dex.
  4. engine probe  looks for the engine's fingerprints (libil2cpp.so,
                   global-metadata.dat, Assembly-CSharp.dll, libgodot*.so,
                   *.pck, libcocos2d*.so, .jsc bundles, libUE4.so / .pak).
  5. per-engine code
                   unity-mono  -> ilspycmd decompiles every Assembly-*.dll to C#.
                   unity-il2cpp-> Il2CppDumper (libil2cpp.so + global-metadata.dat)
                                 -> dump.cs + DummyDll/, then ilspycmd on the
                                 dummy assemblies = readable C#.
                   godot       -> tools/study/godot_pck.py extracts the .pck.
                   cocos       -> js bundles are copied as-is (.jsc = xxtea
                                 bytecode, key usually in settings/main.js).
                   unreal      -> *.pak files listed; use UEViewer (see doc).
  6. unity assets  UnityPy over assets/bin/Data (globalgamemanagers, levels,
                   sharedassets, resources, *.assets, *.unity3d bundles):
                   Texture2D/Sprite -> png, Mesh -> obj (3D!), TextAsset ->
                   bytes, AudioClip -> exported when fmod allows. An inventory
                   json lands next to the files.

Everything is written under OUTDIR/<game>/ :
    unpacked/            raw container contents
    apktool/             decoded resources + manifest
    java/                jadx sources
    code/                engine code dumps (C# / dump.cs / js)
    assets/texture2d/    png images (2D art)
    assets/sprites/      sprite atlas slices
    assets/meshes/       .obj 3D models
    assets/text/         TextAssets (configs, JSON, dialogue...)
    REPORT.json          everything found, per step

Required external tools (auto-located under $STUDY_TOOLS, default
~/.cache/study_tools):  jadx/bin/jadx  apktool.jar  il2cppdumper/Il2CppDumper.dll
dotnet (runtime for both)  + ilspycmd on PATH (~/.dotnet/tools). Missing tools
are skipped with a warning - the pipeline still runs.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

_env_tools = os.environ.get("STUDY_TOOLS", "").strip()
STUDY_TOOLS = Path(_env_tools) if _env_tools else Path("/nonexistent")
if not STUDY_TOOLS.exists():
    for cand in (Path("/home/z/my-project/.cache/study_tools"),
                 Path.home() / ".cache/study_tools"):
        if cand.exists():
            STUDY_TOOLS = cand
            break
DOTNET = STUDY_TOOLS / "dotnet" / "dotnet"


def log(msg: str) -> None:
    print(msg, flush=True)


def run(cmd: list[str], cwd: Path | None = None, env: dict | None = None) -> tuple[int, str]:
    e = dict(os.environ)
    if env:
        e.update(env)
    if str(STUDY_TOOLS / "dotnet") not in e.get("PATH", "") and DOTNET.exists():
        e["DOTNET_ROOT"] = str(STUDY_TOOLS / "dotnet")
        e["PATH"] = f"{STUDY_TOOLS / 'dotnet'}:{Path.home() / '.dotnet/tools'}:{e.get('PATH','')}"
    try:
        p = subprocess.run(cmd, cwd=cwd, env=e, capture_output=True, text=True, timeout=1800)
        return p.returncode, (p.stdout or "") + (p.stderr or "")
    except FileNotFoundError:
        return 127, "tool not found"


def unzip(src: Path, dest: Path, limit_mb: int = 6000) -> int:
    dest.mkdir(parents=True, exist_ok=True)
    n = 0
    with zipfile.ZipFile(src) as z:
        for info in z.infolist():
            if info.is_dir():
                continue
            target = dest / info.filename
            if not str(target.resolve()).startswith(str(dest.resolve())):
                continue  # zip-slip guard
            target.parent.mkdir(parents=True, exist_ok=True)
            with z.open(info) as f, open(target, "wb") as g:
                shutil.copyfileobj(f, g)
            n += 1
    return n


def which_tool(rel: str, name: str) -> Path | None:
    p = STUDY_TOOLS / rel
    if p.exists():
        return p
    w = shutil.which(name)
    return Path(w) if w else None


# ------------------------------------------------------------ engine probing

def probe_engine(root: Path) -> dict:
    libs = list(root.rglob("lib/*.so")) + list(root.rglob("lib/**/*.so"))
    libnames = {p.name.lower() for p in libs}
    assets = root / "assets"
    out: dict = {"engine": "unknown", "signatures": [], "notes": []}

    def mark(e: str, sig: str) -> None:
        out["signatures"].append(sig)
        if out["engine"] == "unknown":
            out["engine"] = e

    if any("libunity" in n for n in libnames):
        if any("libil2cpp" in n for n in libnames):
            mark("unity-il2cpp", "libil2cpp.so")
        meta = list(root.rglob("global-metadata.dat"))
        if meta:
            mark("unity-il2cpp", str(meta[0].relative_to(root)))
        if list(root.rglob("Assembly-CSharp.dll")):
            mark("unity-mono", "Assembly-CSharp.dll")
        if out["engine"] == "unknown":
            mark("unity", "libunity.so")
    if list(root.rglob("Assembly-CSharp.dll")):
        mark("unity-mono", "Assembly-CSharp.dll")
    # unity data with the libs stripped - the classic .obb payload shape
    if out["engine"] == "unknown" and (
            list(root.rglob("data.unity3d")) or list(root.rglob("globalgamemanagers"))
            or list(root.rglob("boot.config"))):
        mark("unity-data", "data.unity3d / globalgamemanagers / boot.config")
    if any("libgodot" in n for n in libnames):
        mark("godot", "libgodot*.so")
    if list(root.rglob("*.pck")):
        mark("godot", ".pck")
    if any("cocos" in n for n in libnames):
        mark("cocos", "libcocos2d*.so")
    if list(root.rglob("*.jsc")) or list((assets / "src").rglob("*.js")) if (assets / "src").exists() else False:
        mark("cocos", "*.jsc / assets/src/*.js")
    if any("libue4" in n or "libunreal" in n for n in libnames):
        mark("unreal", "libUE4.so")
    if list(root.rglob("*.pak")):
        mark("unreal", "*.pak")
    # script engines worth calling out
    for pat, tag in (("*.js", "javascript-bundle"), ("*.lua", "lua"), ("*.luac", "luac")):
        hits = [p for p in root.rglob(pat) if p.stat().st_size > 50_000 and "node_modules" not in str(p)]
        if hits:
            out["notes"].append(f"{tag}: {len(hits)} files (largest {max(hits,key=lambda p:p.stat().st_size).stat().st_size} B)")
    return out


# ------------------------------------------------------------ per-engine code

def decompile_code(root: Path, outdir: Path, engine: dict, max_dlls: int = 12) -> dict:
    info: dict = {"steps": []}
    eng = engine["engine"]

    if eng.startswith("unity"):
        # mono path
        dlls = sorted(root.rglob("Assembly-CSharp*.dll")) + \
               sorted(root.rglob("Assembly-*.dll")) + sorted(root.rglob("*.dll"))
        dlls = [d for d in dlls if "DummyDll" not in str(d)]
        # keep only managed-looking dlls (skip native/netstandard noise)
        dlls = [d for d in dlls if d.stat().st_size > 4096][:max_dlls * 4]
        if dlls:
            code_out = outdir / "code" / "csharp-mono"
            ok = 0
            for dll in dlls[:max_dlls]:
                dest = code_out / dll.stem
                dest.mkdir(parents=True, exist_ok=True)
                rc, outp = run(["ilspycmd", "-p", "-o", str(dest), str(dll)])
                info["steps"].append({"ilspy": str(dll.name), "rc": rc})
                if rc == 0:
                    ok += 1
            if ok:
                info["csharp_mono_files"] = ok

        # il2cpp path
        meta = list(root.rglob("global-metadata.dat"))
        il2 = [p for p in root.rglob("libil2cpp.so")]
        if meta and il2:
            dump_dir = outdir / "code" / "il2cpp"
            dump_dir.mkdir(parents=True, exist_ok=True)
            il2cpp_dumper = which_tool("il2cppdumper/Il2CppDumper.dll", "Il2CppDumper")
            dotnet = DOTNET if DOTNET.exists() else shutil.which("dotnet")
            if il2cpp_dumper and dotnet:
                rc, outp = run([str(dotnet), str(il2cpp_dumper), str(il2[0].resolve()), str(meta[0].resolve()),
                                str(dump_dir.resolve())], cwd=dump_dir)
                info["steps"].append({"il2cppdumper_rc": rc, "tail": outp.strip().splitlines()[-3:] if outp.strip() else []})
                # decompile the dummy dlls to real C#
                dummy = dump_dir / "DummyDll"
                if dummy.exists():
                    cs_out = outdir / "code" / "csharp-il2cpp"
                    n = 0
                    for dll in sorted(dummy.rglob("Assembly-CSharp*.dll"))[:max_dlls]:
                        dest = cs_out / dll.stem
                        dest.mkdir(parents=True, exist_ok=True)
                        rc2, _ = run(["ilspycmd", "-p", "-o", str(dest), str(dll)])
                        if rc2 == 0:
                            n += 1
                    if n:
                        info["csharp_il2cpp_assemblies"] = n
            else:
                info["steps"].append({"il2cppdumper": "missing - install via docs/DECOMPILATION.md"})

    if eng == "godot":
        pcks = list(root.rglob("*.pck"))
        if pcks:
            pck_tool = Path(__file__).parent / "godot_pck.py"
            for pck in pcks[:3]:
                rc, outp = run([sys.executable, str(pck_tool), str(pck), "-o",
                                str(outdir / "code" / "godot_pck" / pck.stem)])
                info["steps"].append({"godot_pck": pck.name, "rc": rc})

    if eng == "cocos":
        js_dir = outdir / "code" / "js"
        js_dir.mkdir(parents=True, exist_ok=True)
        n = 0
        for pat in ("*.js", "*.jsc"):
            for p in root.rglob(pat):
                if p.stat().st_size < 1024:
                    continue
                rel = p.relative_to(root)
                dest = js_dir / rel
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(p, dest)
                n += 1
        info["js_files_copied"] = n

    return info


# ------------------------------------------------------------ unity assets

def extract_unity_assets(root: Path, outdir: Path, max_assets: int = 5000) -> dict:
    try:
        import UnityPy  # noqa: PLC0415
    except ImportError:
        return {"error": "UnityPy not installed (pip install UnityPy)"}
    data_dirs: list[Path] = []
    for pat in ("assets/bin/Data", "assets/**/bin/Data", "data"):
        data_dirs += [p for p in root.glob(pat) if p.is_dir()]
    # unity asset bundles anywhere
    bundles = [p for p in root.rglob("*") if p.suffix.lower() in (".unity3d", ".assets", ".assetbundle")
               and p.stat().st_size > 4096 and "code/" not in str(p)]
    files: list[Path] = []
    for d in data_dirs:
        files += [p for p in d.rglob("*") if p.is_file() and
                  (p.suffix in (".assets", ".resource", ".unity3d", ".assetbundle")
                   or p.name.startswith(("level", "sharedassets", "resources",
                                         "globalgamemanagers", "unity_default")))]
    files += bundles
    files = sorted(set(files), key=lambda p: -p.stat().st_size)[:40]

    tex_dir = outdir / "assets" / "texture2d"
    spr_dir = outdir / "assets" / "sprites"
    mesh_dir = outdir / "assets" / "meshes"
    txt_dir = outdir / "assets" / "text"
    counts = {"texture2d": 0, "sprites": 0, "mesh": 0, "textasset": 0, "audioclip": 0}
    skipped_audio = 0

    for f in files:
        try:
            env = UnityPy.load(str(f))
        except Exception as e:  # noqa: BLE001
            log(f"  ! unitypy load {f.name}: {e}")
            continue
        for obj in env.objects:
            if sum(counts.values()) >= max_assets:
                break
            try:
                tname = obj.type.name
            except Exception:  # noqa: BLE001
                continue
            try:
                if tname == "Texture2D":
                    data = obj.read()
                    img = data.image
                    if img is None:
                        continue
                    if img.width * img.height < 64:  # noise textures
                        continue
                    dest = tex_dir / f"{f.stem}_{data.m_Name[:60]}.png"
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    img.save(dest)
                    counts["texture2d"] += 1
                elif tname == "Sprite":
                    data = obj.read()
                    img = data.image
                    if img is None or img.width * img.height < 64:
                        continue
                    dest = spr_dir / f"{f.stem}_{data.m_Name[:60]}.png"
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    img.save(dest)
                    counts["sprites"] += 1
                elif tname == "Mesh":
                    data = obj.read()
                    try:
                        objtext = data.export()
                    except Exception:  # noqa: BLE001
                        continue
                    dest = mesh_dir / f"{f.stem}_{data.m_Name[:60]}.obj"
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    dest.write_text(objtext, encoding="utf-8", errors="replace")
                    counts["mesh"] += 1
                elif tname == "TextAsset":
                    data = obj.read()
                    raw = data.m_Script
                    b = raw.encode("utf-8", "surrogateescape") if isinstance(raw, str) else bytes(raw)
                    dest = txt_dir / f"{f.stem}_{data.m_Name[:60]}.bin"
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    dest.write_bytes(b)
                    counts["textasset"] += 1
                elif tname == "AudioClip":
                    skipped_audio += 1
            except Exception:  # noqa: BLE001 - one bad object must not kill the pass
                continue
        if sum(counts.values()) >= max_assets:
            break

    counts["skipped_audioclips"] = skipped_audio
    counts["source_files"] = len(files)
    return counts


# ------------------------------------------------------------ main pipeline

def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input", help=".apk | .xapk | .obb")
    ap.add_argument("-o", "--out", default=None, help="output dir (default study_out/decompiled/<stem>)")
    ap.add_argument("--no-assets", action="store_true")
    ap.add_argument("--no-code", action="store_true")
    ap.add_argument("--max-assets", type=int, default=5000)
    args = ap.parse_args()

    src = Path(args.input)
    if not src.exists():
        raise SystemExit(f"no such file: {src}")
    out = Path(args.out) if args.out else Path("study_out/decompiled") / src.stem
    out.mkdir(parents=True, exist_ok=True)
    report: dict = {"input": str(src), "output": str(out)}

    # 1. containers -------------------------------------------------------
    unpacked = out / "unpacked"
    suffix = src.suffix.lower()
    if suffix in (".xapk", ".obb", ".apks", ".zip"):
        log(f"[1] unpacking container {src.name}")
        report["unpacked_files"] = unzip(src, unpacked)
        # xapk: extract every inner apk; obb: contents are assets already
        inner_apks = sorted(unpacked.rglob("*.apk"))
        for iapk in inner_apks:
            sub = unpacked / iapk.stem
            sub.mkdir(exist_ok=True)
            unzip(iapk, sub)
            report.setdefault("inner_apks", []).append({"apk": iapk.name, "files": len(list(sub.rglob('*')))})
    elif suffix == ".apk":
        log(f"[1] unpacking apk {src.name}")
        report["unpacked_files"] = unzip(src, unpacked)
    else:
        raise SystemExit(f"unsupported container: {suffix} (use .apk/.xapk/.obb)")

    # analysis root = the biggest unpacked apk dir (or unpacked itself for obb)
    apk_dirs = [p for p in unpacked.iterdir() if p.is_dir()] if suffix == ".xapk" else []
    if apk_dirs:
        base = max(apk_dirs, key=lambda p: sum(f.stat().st_size for f in p.rglob('*') if f.is_file()))
    else:
        base = unpacked
    report["analysis_root"] = str(base)
    log(f"[1] analysis root: {base.name}")
    # the engine may be split across the base apk (data) and config apks (libs),
    # so every engine-facing step scans the WHOLE unpacked tree
    scan = unpacked

    # 2. pick the APK that actually gets decoded (base apk of an xapk)
    if suffix == ".apk":
        target_apk = src
    else:
        inners = [a for a in sorted(unpacked.rglob("*.apk"))
                  if "config" not in a.stem.lower() and "assetpack" not in a.stem.lower()]
        target_apk = inners[0] if inners else src
    report["target_apk"] = target_apk.name
    log(f"[2] decoding apk: {target_apk.name}")

    # 2. apktool resources ------------------------------------------------
    apktool = which_tool("apktool.jar", "apktool")
    if suffix in (".obb", ".apks", ".zip"):
        log("[2] obb/zip payload - apktool not applicable (no apk structure)")
    elif apktool:
        log("[2] apktool resources")
        rc, outp = run(["java", "-jar", str(apktool), "d", "-f", "--no-src",
                        "-o", str(out / "apktool"), str(target_apk)])
        report["apktool_rc"] = rc
        if rc != 0:
            log(f"  ! apktool: {outp.strip().splitlines()[-1:]}")
    else:
        log("[2] apktool missing - skipping resources")

    # 3. jadx sources ------------------------------------------------------
    jadx = which_tool("jadx/bin/jadx", "jadx")
    if suffix in (".obb", ".apks", ".zip"):
        log("[3] obb/zip payload - jadx not applicable (no dex)")
    elif jadx:
        log("[3] jadx java sources")
        rc, outp = run([str(jadx), "-d", str(out / "java"), "--no-res",
                        "-j", "2", str(target_apk)],
                       env={"JAVA_TOOL_OPTIONS": "-Xmx2048m"})
        report["jadx_rc"] = rc
        jf = list((out / "java").rglob("*.java")) if (out / "java").exists() else []
        report["java_files"] = len(jf)
        log(f"  = {len(jf)} .java files")
    else:
        log("[3] jadx missing - skipping java")

    # 4. engine probe ------------------------------------------------------
    log("[4] engine probe")
    engine = probe_engine(scan)
    report["engine"] = engine
    log(f"  = engine: {engine['engine']}  sigs={engine['signatures']}")

    # 5. code --------------------------------------------------------------
    if not args.no_code and engine["engine"] != "unknown":
        log("[5] engine code decompilation")
        report["code"] = decompile_code(scan, out, engine)

    # 6. unity assets ------------------------------------------------------
    if not args.no_assets and engine["engine"].startswith("unity"):
        log("[6] UnityPy asset extraction")
        counts = extract_unity_assets(scan, out, args.max_assets)
        report["unity_assets"] = counts
        log(f"  = {counts}")

    (out / "REPORT.json").write_text(json.dumps(report, indent=2, default=str))
    log(f"[done] {out} - see REPORT.json")


if __name__ == "__main__":
    main()
