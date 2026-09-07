#!/usr/bin/env python3
"""godot_pck.py - extract a Godot Engine .pck pack (formats 2, 3 and 4 - Godot
3.x through 4.6+), standalone or embedded inside an engine binary / apk
libgodot*.so.

    python3 tools/study/godot_pck.py <file.pck | libgodot.so | any binary> [-o OUTDIR]

Format (from godot core/io/file_access_pack.cpp, v3/v4 supported):
    magic "GDPC" u32
    u32 pack_format_version  (2 | 3 | 4)
    u32 ver_major, u32 ver_minor, u32 ver_patch
    u32 pack_flags   bit0 PACK_DIR_ENCRYPTED, bit1 PACK_REL_FILEBASE (always set for v3+),
                     bit2 PACK_SPARSE_BUNDLE (v4)
    u64 file_base    (absolute offsets base; += pck_start_pos for v3+/relfilebase)
    v3/v4: u64 dir_offset (+ pck_start_pos); v4 sparse+encrypted: + 32 byte salt
    v2: 64 bytes reserved
    directory at dir_offset (v3/v4) or right after the header (v2):
        u32 file_count
        per file: u32 path_len, path utf8, u64 ofs, u64 size, md5 16 bytes,
                  u32 flags (bit0 encrypted, bit1 removal, bit2 delta-patch)
    real file offset = file_base + ofs
Encrypted packs / encrypted directories are reported but not decrypted
(needs the project's script encryption key).
Embedded packs are found by scanning the binary for the GDPC magic (both the
footer form with a trailing size and the plain scan).
"""

import argparse
import json
import struct
import sys
from pathlib import Path

try:
    import zstandard as _zstd  # optional: decodes compressed .gdc bytecode
except ImportError:  # pragma: no cover
    _zstd = None

MAGIC = b"GDPC"
GDSC_MAGIC = b"GDSC"
PACK_DIR_ENCRYPTED = 1 << 0
PACK_REL_FILEBASE = 1 << 1
PACK_SPARSE_BUNDLE = 1 << 2
PACK_FILE_ENCRYPTED = 1 << 0
PACK_FILE_REMOVAL = 1 << 1


def log(m: str) -> None:
    print(m, flush=True)


def find_embedded(data: bytes) -> int:
    """Return the offset of an embedded pck inside a binary, or -1."""
    if len(data) > 8 and data[-4:] == MAGIC:
        size = struct.unpack_from("<I", data, len(data) - 8)[0]
        off = len(data) - 8 - size
        if off >= 0 and data[off:off + 4] == MAGIC:
            return off
    return data.find(MAGIC)


def read_pck(data: bytes, start: int):
    off = start
    if data[off:off + 4] != MAGIC:
        raise ValueError("not a pck (bad magic)")
    off += 4
    fmt, = struct.unpack_from("<I", data, off); off += 4
    if fmt not in (2, 3, 4):
        raise ValueError(f"unsupported pack format {fmt} (want 2/3/4)")
    vmaj, vmin, vpat = struct.unpack_from("<III", data, off); off += 12
    meta = {"format": fmt, "godot": f"{vmaj}.{vmin}.{vpat}"}

    flags, = struct.unpack_from("<I", data, off); off += 4
    file_base, = struct.unpack_from("<Q", data, off); off += 8
    meta["pack_flags"] = flags
    if fmt in (3, 4) or flags & PACK_REL_FILEBASE:
        file_base += start
    if flags & PACK_DIR_ENCRYPTED:
        meta["encrypted_directory"] = True

    if fmt in (3, 4):
        dir_off, = struct.unpack_from("<Q", data, off); off += 8
        dir_off += start
        if fmt == 4 and (flags & PACK_SPARSE_BUNDLE) and (flags & PACK_DIR_ENCRYPTED):
            off += 32  # encrypted-directory salt
        off = dir_off
    else:
        off += 64  # v2 reserved

    count, = struct.unpack_from("<I", data, off); off += 4
    entries = []
    for _ in range(count):
        plen, = struct.unpack_from("<I", data, off); off += 4
        path = data[off:off + plen].decode("utf-8", "replace"); off += plen
        foff, = struct.unpack_from("<Q", data, off); off += 8
        fsize, = struct.unpack_from("<Q", data, off); off += 8
        off += 16  # md5
        fflags, = struct.unpack_from("<I", data, off); off += 4
        entries.append({
            "path": path,
            "offset": file_base + foff,
            "size": fsize,
            "flags": fflags,
        })
    meta["files"] = count
    return meta, entries


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("input")
    ap.add_argument("-o", "--out", default=None)
    args = ap.parse_args()

    src = Path(args.input)
    data = src.read_bytes()
    start = 0
    if data[:4] != MAGIC:
        start = find_embedded(data)
        if start < 0:
            raise SystemExit("no GDPC pack found (standalone or embedded)")
        log(f"[embedded pck found at offset {start:#x}]")
    try:
        meta, entries = read_pck(data, start)
    except Exception as e:  # noqa: BLE001
        raise SystemExit(f"pck parse failed: {e}")

    out = Path(args.out) if args.out else Path("study_out/decompiled") / (src.stem + "_pck")
    out.mkdir(parents=True, exist_ok=True)
    log(f"[pack] godot {meta['godot']} format {meta['format']}, {meta['files']} files -> {out}")

    saved = 0
    encrypted = 0
    removed = 0
    for e in entries:
        if e["flags"] & PACK_FILE_REMOVAL:
            removed += 1
            continue
        if e["flags"] & PACK_FILE_ENCRYPTED or meta.get("encrypted_directory"):
            encrypted += 1
            continue
        p = e["path"].split("\x00", 1)[0].strip()
        if not p:
            continue
        if p.startswith("res://"):
            p = p[6:]
        dest = (out / p).resolve()
        if not str(dest).startswith(str(out.resolve())):
            continue
        end = min(e["offset"] + e["size"], len(data))
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data[e["offset"]:end])
        saved += 1

    (out / "PCK_REPORT.json").write_text(json.dumps(
        {**meta, "extracted": saved, "encrypted_skipped": encrypted,
         "removal_entries": removed}, indent=2))
    log(f"[done] {saved} files extracted, {encrypted} encrypted (skipped), "
        f"{removed} removal entries")

    # godot 4.4+ packs store scripts as .gdc (GDSC header + zstd frame, token
    # stream, identifier strings as u32-per-char XOR 0xB6). Pull the strings
    # out next to each file so the pack is actually readable for study.
    if _zstd:
        n = 0
        for gdc in out.rglob("*.gdc"):
            try:
                strings = gdc_strings(gdc.read_bytes())
            except Exception:  # noqa: BLE001
                continue
            if strings:
                gdc.with_suffix(gdc.suffix + ".strings.txt").write_text(
                    "\n".join(strings), encoding="utf-8", errors="replace")
                n += 1
        log(f"[gdc] strings decoded from {n} compiled scripts")


def gdc_strings(blob: bytes) -> list[str]:
    """Decode identifier strings from a (possibly zstd-compressed) GDSC blob."""
    body = blob
    if blob[:4] == GDSC_MAGIC and len(blob) > 12:
        usize, = struct.unpack_from("<I", blob, 8)
        try:
            body = _zstd.ZstdDecompressor().decompress(blob[12:], max_output_size=usize * 4 + 4096)
        except Exception:  # noqa: BLE001
            body = blob
    strings = []
    i = 0
    n = len(body)
    while i + 8 <= n:
        strlen, = struct.unpack_from("<I", body, i)
        if 1 <= strlen <= 256 and i + 4 + strlen * 4 <= n:
            raw = body[i + 4:i + 4 + strlen * 4]
            # u32-per-char, XOR 0xB6 - Godot 4.4+ token string obfuscation
            dec = bytes(raw[k] ^ 0xB6 for k in range(0, strlen * 4, 4))
            try:
                s = dec.decode("utf-8")
            except UnicodeDecodeError:
                i += 4
                continue
            if s and all(31 < ord(c) < 0x2FFF for c in s):
                strings.append(s)
                i += 4 + strlen * 4
                continue
        i += 4
    return strings


if __name__ == "__main__":
    main()
