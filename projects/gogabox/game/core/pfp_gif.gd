extends RefCounted
class_name PfpGif
## THE GIF DECODER (v042-1, THE PFP MEDIA LAW) - the engine has no runtime
## GIF decoder, so the box ships its own: a pure-GDScript GIF87a/89a
## reader (LZW + frame disposal) for PROFILE FACES only.
##
## The budget: PFP-sized media (the import caps long side at 480 and 150
## frames before decode). Delays ride the GCE blocks; transparent-index
## pixels blend over the previous canvas per the disposal method.

## Decode raw GIF bytes -> {frames: [Image], delays_ms: [int]} or {err}.
static func decode(bytes: PackedByteArray, max_side := 480,
                max_frames := 150) -> Dictionary:
        var b := bytes
        if b.size() < 13:
                return {"err": "truncated"}
        var head := b.slice(0, 6).get_string_from_ascii()
        if head != "GIF87a" and head != "GIF89a":
                return {"err": "not a gif"}
        var p := 6
        var sw := _u16le(b, p)
        var sh := _u16le(b, p + 2)
        p += 4
        var packed := b[p]
        p += 1
        p += 2        # bg color index + aspect (unused)
        var gct: Array = []
        if (packed & 0x80) != 0:
                var gct_n := 2 << (packed & 0x07)
                for i in gct_n:
                        gct.append(_col(b, p + i * 3))
                p += gct_n * 3
        var frames: Array = []
        var delays: Array = []
        var canvas := Image.create_empty(sw, sh, false, Image.FORMAT_RGBA8)
        var prev_canvas: Image = null
        var gce := {"delay": 10, "trans": -1, "disposal": 0}
        while p < b.size():
                var block := b[p]
                p += 1
                if block == 0x3B:          # trailer
                        break
                elif block == 0x21:        # extension
                    var label := b[p]
                    p += 1
                    if label == 0xF9:      # graphic control
                            var sz := b[p]
                            p += 1
                            if sz >= 4:
                                    var fl := b[p]
                                    gce["disposal"] = (fl >> 2) & 0x07
                                    gce["trans"] = b[p + 3] if (fl & 0x01) != 0 else -1
                                    gce["delay"] = _u16le(b, p + 1)
                            p += sz
                            if b[p] == 0:
                                    p += 1
                    else:                  # skip the sub-block chain
                            while p < b.size():
                                    var ssz := b[p]
                                    p += 1
                                    if ssz == 0:
                                            break
                                    p += ssz
                elif block == 0x2C:        # image descriptor
                        var ix := _u16le(b, p)
                        var iy := _u16le(b, p + 2)
                        var iw := _u16le(b, p + 4)
                        var ih := _u16le(b, p + 6)
                        var ip := b[p + 8]
                        p += 9
                        var lct: Array = gct
                        if (ip & 0x80) != 0:
                                lct = []
                                var lct_n := 2 << (ip & 0x07)
                                for i in lct_n:
                                        lct.append(_col(b, p + i * 3))
                                p += lct_n * 3
                        var interlace := (ip & 0x40) != 0
                        var min_code := b[p]
                        p += 1
                        # gather the LZW data stream
                        var data := PackedByteArray()
                        while p < b.size():
                                var ssz := b[p]
                                p += 1
                                if ssz == 0:
                                        break
                                data.append_array(b.slice(p, p + ssz))
                                p += ssz
                        # THE PFP BUDGET: over-budget GIFs stop here
                        if frames.size() >= max_frames or iw > max_side \
                                        or ih > max_side:
                                if frames.is_empty():
                                        return {"err": "gif over budget"}
                                break
                        var indices := _lzw(data, min_code, iw * ih)
                        prev_canvas = null
                        if gce["disposal"] == 3:
                                prev_canvas = canvas.duplicate()
                        # dispose BEFORE painting (methods 2/3 clear the region)
                        if gce["disposal"] == 2:
                                var er := Rect2i(ix, iy, iw, ih)
                                for yy in range(maxi(0, er.position.y),
                                                mini(sh, er.end.y)):
                                        for xx in range(maxi(0, er.position.x),
                                                        mini(sw, er.end.x)):
                                                canvas.set_pixel(xx, yy,
                                                                Color(0, 0, 0, 0))
                        elif gce["disposal"] == 3 and prev_canvas != null:
                                canvas = prev_canvas
                        # paint
                        var trans := int(gce["trans"])
                        var row := 0
                        for n in ih:
                                var yy := iy + (n if not interlace \
                                                else _interlace_y(n, ih))
                                if yy < 0 or yy >= sh:
                                        continue
                                for xx in iw:
                                        if ix + xx >= sw:
                                                continue
                                        var idx := row * iw + xx
                                        if idx >= indices.size():
                                                continue
                                        var pi := int(indices[idx])
                                        if pi == trans:
                                                continue
                                        if pi < lct.size():
                                                canvas.set_pixel(ix + xx, yy,
                                                                lct[pi])
                                row += 1
                        frames.append(canvas.duplicate())
                        delays.append(maxi(2, int(gce["delay"])))
                        gce = {"delay": 10, "trans": -1, "disposal": 0}
                else:
                        break              # unknown block - stop honestly
        if frames.is_empty():
                return {"err": "no frames"}
        return {"frames": frames, "delays_ms": delays}

static func _interlace_y(row: int, h: int) -> int:
        var starts := [0, 4, 2, 1]
        var steps := [8, 8, 4, 2]
        var acc := 0
        for pass_i in 4:
                var rows_in_pass := ceili(float(h - starts[pass_i]) \
                                / float(steps[pass_i]))
                if row < acc + rows_in_pass:
                        return starts[pass_i] + (row - acc) * steps[pass_i]
                acc += rows_in_pass
        return row

static func _u16le(b: PackedByteArray, at: int) -> int:
        return int(b[at]) | (int(b[at + 1]) << 8)

static func _col(b: PackedByteArray, at: int) -> Color:
        return Color8(int(b[at]), int(b[at + 1]), int(b[at + 2]))

## THE LZW: GIF variable-width codes, clear/EOI, dict of index runs.
static func _lzw(data: PackedByteArray, min_code: int, pixel_count: int) -> PackedInt32Array:
        var out := PackedInt32Array()
        out.resize(pixel_count)
        var oi := 0
        var clear_code := 1 << min_code
        var eoi := clear_code + 1
        var code_size := min_code + 1
        var dict := {}
        var run := PackedInt32Array()
        var bits := 0
        var acc := 0
        var di := 0
        var next_code := eoi + 1
        while di < data.size() and oi < pixel_count:
                acc |= int(data[di]) << bits
                bits += 8
                di += 1
                while bits >= code_size:
                        var code := acc & ((1 << code_size) - 1)
                        acc >>= code_size
                        bits -= code_size
                        if code == clear_code:
                                code_size = min_code + 1
                                dict.clear()
                                next_code = eoi + 1
                                run = PackedInt32Array()
                                continue
                        if code == eoi:
                                return out
                        var entry := PackedInt32Array()
                        if dict.has(code):
                                entry = dict[code]
                        elif not run.is_empty() and code == next_code:
                                entry = run.duplicate()
                                entry.append(run[0])
                        else:
                                return out        # corrupt stream - stop
                        for v in entry:
                                if oi < pixel_count:
                                        out[oi] = v
                                        oi += 1
                        if not run.is_empty() and next_code < (1 << 12):
                                var nk := run.duplicate()
                                nk.append(entry[0])
                                dict[next_code] = nk
                                next_code += 1
                                if next_code >= (1 << code_size) \
                                                and code_size < 12:
                                        code_size += 1
                        run = entry
        return out
