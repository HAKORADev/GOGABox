class_name GogaDiscover
extends RefCounted
## THE DISCOVER ENGINE (v043 - THE_PLATFORM_ANSWER.md's core graduate).
##
## Sources: what the discover feed serves. Two families:
##   LOCAL   - a folder root, a parent of roots, or a "virtual repo" (a
##             folder carrying gogabox.repo.json + game roots: the FULL
##             github-side flow simulated with zero network - THE LOCAL
##             SIMULATION LAW: the binary validates everything itself,
##             the local flow IS the contract the remote flow answers to).
##   GITHUB  - a repo that serves GOGAs/discover/index/source.json over
##             RAW http (THE NO-API-LIMIT LAW: the known-file convention -
##             a well-known path IS the API; raw.githubusercontent.com
##             never burns the REST rate limits).
##
## THE SOURCE REGISTRY: GOGAs/discover/sources.json - the user-added
## sources. The OFFICIAL source is hardcoded engine-side (the owner's
## repo; "official/community/hobbyist are not game maker-specific, they
## are hardcoded in the engine").
##
## THE TIERS (engine-decided, never source-claimed):
##   official  - the hardcoded repo list
##   community - listed in the official repo's discover/REPOS.txt (the
##               two-step publish: make repo, PR the link, CI validates)
##   hobbyist  - everything else (manually added / imported ids)
##
## THE DATA-PROCESSING MAP (what lives where):
##   feed metadata (source.json + per-game index.json) -> refetched per
##     feed pull, small and re-fetchable - nothing cached in user-data
##   downloads assemble whole in GOGAs/.cache/discover/dl/<pkg id>/ then
##     import moves them into GOGAs/games/<pkg id>/ (validated or refused)
##   saves and user data never touch .cache (the portable-save law)

const OFFICIAL_REPOS := ["HAKORADev/GOGABox"]
const REPOS_TXT := "GOGAs/discover/REPOS.txt"
const SOURCE_JSON := "GOGAs/discover/index/source.json"
const SCHEMA := 1
const RAW_HOST := "https://raw.githubusercontent.com"

# ------------------------------------------------------------- the helpers

static func _tree() -> SceneTree:
        return Engine.get_main_loop() as SceneTree

static func _goga() -> Node:
        return _tree().root.get_node_or_null("GOGA")

static func _vcmp(a: String, b: String) -> int:
        var g := _goga()
        if g != null:
                return int(g.call("version_compare", a, b))
        var pa := a.split(".")
        var pb := b.split(".")
        for i in maxi(pa.size(), pb.size()):
                var va := int(pa[i]) if i < pa.size() else 0
                var vb := int(pb[i]) if i < pb.size() else 0
                if va < vb:
                        return -1
                if va > vb:
                        return 1
        return 0

# ------------------------------------------------------------- the http seat

## Raw HTTP GET -> body text ("" on any failure). THE NO-API-LIMIT LAW's
## transport: this never touches api.github.com - raw file URLs only.
static func http_get(url: String, timeout_s := 15.0) -> String:
        var body := await http_get_bytes(url, timeout_s)
        return body.get_string_from_utf8() if not body.is_empty() else ""

static func http_get_bytes(url: String, timeout_s := 60.0) -> PackedByteArray:
        var http := HTTPRequest.new()
        http.timeout = timeout_s
        http.accept_gzip = true
        http.download_chunk_size = 1 << 20
        var root := _tree().root
        root.add_child(http)
        var err := http.request(url)
        if err != OK:
                http.queue_free()
                return PackedByteArray()
        var res: Array = await http.request_completed
        http.queue_free()
        if int(res[0]) == HTTPRequest.RESULT_SUCCESS and int(res[1]) >= 200 and int(res[1]) < 300:
                return res[3]
        return PackedByteArray()

# ------------------------------------------------------------- the tiers

static func official_repo(repo: String) -> bool:
        return OFFICIAL_REPOS.has(repo)

## The community register: the official repo's REPOS.txt (raw, no API).
## One repo per line ("user/repo"), '#' comments. Empty on any failure -
## the caller degrades to hobbyist honestly.
static func community_repos() -> Array:
        var out: Array = []
        for repo in OFFICIAL_REPOS:
                var url := "%s/%s/main/%s" % [RAW_HOST, repo, REPOS_TXT]
                var txt := await http_get(url, 8.0)
                if txt == "":
                        continue
                for line in txt.split("\n"):
                        var s := line.strip_edges()
                        if s == "" or s.begins_with("#"):
                                continue
                        if not out.has(s):
                                out.append(s)
        return out

static func tier_for(repo: String, community: Array) -> String:
        if official_repo(repo):
                return "official"
        if community.has(repo):
                return "community"
        return "hobbyist"

# ------------------------------------------------------------- the sources

## The user's source list (GOGAs/discover/sources.json). Each:
##   {"kind": "github"|"local", "repo": "user/repo", "branch": "main",
##    "path": "/abs/dir", "name": "..."}
static func sources() -> Array:
        var f := FileAccess.open(_sources_path(), FileAccess.READ)
        if f == null:
                return []
        var v: Variant = JSON.parse_string(f.get_as_text())
        f.close()
        return v if (v is Array) else []

static func add_source(s: Dictionary) -> bool:
        var list := sources()
        for old in list:
                if String(old.get("repo", "")) == String(s.get("repo", "")) \
                                and String(old.get("path", "")) == String(s.get("path", "")):
                        return false
        list.append(s)
        _save_sources(list)
        return true

static func remove_source(index: int) -> void:
        var list := sources()
        if index >= 0 and index < list.size():
                list.remove_at(index)
                _save_sources(list)

static func _save_sources(list: Array) -> void:
        var path := _sources_path()
        DirAccess.make_dir_recursive_absolute(path.get_base_dir())
        var f := FileAccess.open(path, FileAccess.WRITE)
        if f != null:
                f.store_string(JSON.stringify(list, "  "))
                f.close()

static func _sources_path() -> String:
        var g := _goga()
        if g != null:
                return String(g.call("discover_dir")).path_join("sources.json")
        return "user://GOGAs/discover/sources.json"

# ------------------------------------------------------------- the feed

static func installed_map() -> Dictionary:
        var out := {}
        var g := _goga()
        if g == null:
                return out
        for e in (g.call("entries") as Array):
                out[String(e.get("pkg_id", ""))] = String(e.get("installed_version", "0"))
        return out

## The discover feed: every source's game rows, merged. Each row:
##   {pkg_id, game_id, title, tag, version, age, content, genres, os,
##    size, updated, versions_count, tier, source, desc, thumb, installed}
static func fetch_feed() -> Dictionary:
        var community := await community_repos()
        var rows: Array = []
        var notes: Array = []
        # the OFFICIAL source is always present (the hardcoded engine law)
        for repo in OFFICIAL_REPOS:
                rows.append_array(await _feed_for_github(repo, "main", community, installed_map(), notes))
        # the user's sources
        for s in sources():
                if String(s.get("kind", "")) == "github":
                        var repo := String(s.get("repo", ""))
                        if OFFICIAL_REPOS.has(repo):
                                continue   # already served
                        rows.append_array(await _feed_for_github(repo,
                                        String(s.get("branch", "main")), community,
                                        installed_map(), notes))
                elif String(s.get("kind", "")) == "local":
                        rows.append_array(_feed_for_local(String(s.get("path", "")),
                                        community, installed_map(), notes))
        return {"rows": rows, "notes": notes}

## One github source's feed rows: fetch source.json, then each game's
## index.json - ALL over raw http (the no-api-limit law).
static func _feed_for_github(repo: String, branch: String, community: Array,
                installed: Dictionary, notes: Array) -> Array:
        var base := "%s/%s/%s" % [RAW_HOST, repo, branch]
        var rows: Array = []
        var txt := await http_get("%s/%s" % [base, SOURCE_JSON])
        if txt == "":
                notes.append({"repo": repo, "why": "the source's index file answered nothing (not published yet, or a private/broken repo)"})
                return rows
        var src: Variant = JSON.parse_string(txt)
        if not (src is Dictionary):
                notes.append({"repo": repo, "why": "the source's index file is not a JSON object"})
                return rows
        var tier := tier_for(repo, community)
        for g in ((src as Dictionary).get("games", []) as Array):
                var gd: Dictionary = g
                var index_rel := String(gd.get("index", ""))
                if index_rel == "":
                        continue
                var itxt := await http_get("%s/%s" % [base, index_rel])
                if itxt == "":
                        notes.append({"repo": repo, "why": "game index %s answered nothing" % index_rel})
                        continue
                var idx: Variant = JSON.parse_string(itxt)
                if not (idx is Dictionary):
                        notes.append({"repo": repo, "why": "game index %s is not a JSON object" % index_rel})
                        continue
                var e: Dictionary = idx
                var pkg_id := String(e.get("id", ""))
                var game_base := "%s/%s" % [base, index_rel.trim_suffix("index/index.json")]
                rows.append({
                        "pkg_id": pkg_id,
                        "game_id": String(e.get("game_id", pkg_id)),
                        "title": String(e.get("title", "")),
                        "tag": String(e.get("tag", "")),
                        "version": String(e.get("version", "0")),
                        "age": int(e.get("age", 3)),
                        "content": e.get("content", []),
                        "genres": e.get("genres", {}),
                        "os": e.get("os", ["android", "pc"]),
                        "size": int(e.get("size_bytes", gd.get("size_bytes", 0))),
                        "updated": String(e.get("updated", gd.get("updated", ""))),
                        "versions_count": int(e.get("versions_count", 1)),
                        "tier": tier,
                        "source": repo,
                        "desc": String(e.get("desc", "")),
                        "thumb_url": "%s%s" % [game_base, String(e.get("thumb", ""))],
                        "base_url": game_base,
                        "installed_version": String(installed.get(pkg_id, "")),
                })
        return rows

## One LOCAL source's feed rows: a folder root, a parent of roots, or a
## virtual repo (gogabox.repo.json marks the root of the simulation).
static func _feed_for_local(path: String, community: Array,
                installed: Dictionary, notes: Array) -> Array:
        var rows: Array = []
        if not DirAccess.dir_exists_absolute(path):
                notes.append({"repo": path, "why": "the local source folder does not exist"})
                return rows
        var roots: Array = []
        if FileAccess.file_exists(path.path_join("index/index.json")):
                roots.append(path)
        else:
                var da := DirAccess.open(path)
                if da != null:
                        da.list_dir_begin()
                        var n := da.get_next()
                        while n != "":
                                if da.current_is_dir() and not n.begins_with("."):
                                        var sub := path.path_join(n)
                                        if FileAccess.file_exists(sub.path_join("index/index.json")):
                                                roots.append(sub)
                                n = da.get_next()
                        da.list_dir_end()
        var tier := "hobbyist"
        var repo_name := ""
        var repo_file := path.path_join("gogabox.repo.json")
        if FileAccess.file_exists(repo_file):
                # THE VIRTUAL REPO: the developer's local simulation of the
                # github flow - same files, same validation, zero network
                var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(repo_file))
                if v is Dictionary:
                        repo_name = String((v as Dictionary).get("repo", ""))
                        tier = tier_for(repo_name, community)
        elif official_repo(path.get_file()):
                tier = "official"
        for root in roots:
                var itxt := FileAccess.get_file_as_string(root.path_join("index/index.json"))
                var idx: Variant = JSON.parse_string(itxt)
                if not (idx is Dictionary):
                        notes.append({"repo": root, "why": "the local index is not a JSON object"})
                        continue
                var e: Dictionary = idx
                var pkg_id := String(e.get("id", ""))
                rows.append({
                        "pkg_id": pkg_id,
                        "game_id": String(e.get("game_id", pkg_id)),
                        "title": String(e.get("title", "")),
                        "tag": String(e.get("tag", "")),
                        "version": String(e.get("version", "0")),
                        "age": int(e.get("age", 3)),
                        "content": e.get("content", []),
                        "genres": e.get("genres", {}),
                        "os": e.get("os", ["android", "pc"]),
                        "size": int(e.get("size_bytes", _dir_size(root))),
                        "updated": String(e.get("updated", "")),
                        "versions_count": int(e.get("versions_count", 1)),
                        "tier": tier,
                        "source": repo_name if repo_name != "" else "local:" + path,
                        "desc": String(e.get("desc", "")),
                        "thumb_path": root.path_join(String(e.get("thumb", ""))),
                        "base_url": root,
                        "local": true,
                        "installed_version": String(installed.get(pkg_id, "")),
                })
        return rows

static func _dir_size(path: String) -> int:
        var total := 0
        var da := DirAccess.open(path)
        if da == null:
                return 0
        da.list_dir_begin()
        var n := da.get_next()
        while n != "":
                var full := path.path_join(n)
                if da.current_is_dir():
                        total += _dir_size(full)
                else:
                        var f := FileAccess.open(full, FileAccess.READ)
                        if f != null:
                                total += int(f.get_length())
                                f.close()
                n = da.get_next()
        da.list_dir_end()
        return total

# ------------------------------------------------------------- the search

## THE DISCOVER SEARCH (the owner's sorts): keyword/genre/sub/age/content
## filters + THE SIZE/DATE/VERSIONS arrows - "size+arrow-up means smaller
## to bigger or size arrow down means bigger to smaller, and also date
## up/down for same thing and version up/down based on how many versions
## released for same game". sort: size_up|size_down|date_up|date_down|
## version_up|version_down ("").
static func search(rows: Array, query := "", genre := "", sub := "", age := "",
                content := "", sort := "", tier := "") -> Array:
        var out: Array = []
        var q := query.to_lower().replace(" ", "")
        for r in rows:
                var row: Dictionary = r
                if tier != "" and String(row.get("tier", "")) != tier:
                        continue
                if q != "" and not (q in (String(row.get("title", "")) + " " + String(row.get("pkg_id", ""))).to_lower().replace(" ", "")):
                        continue
                if genre != "" or sub != "":
                        var geo: Dictionary = row.get("genres", {})
                        var mains: Array = (geo.get("main", []) as Array).map(func(t): return String(t).to_lower())
                        var subs: Array = (geo.get("sub", []) as Array).map(func(t): return String(t).to_lower())
                        if genre != "" and not (genre in mains):
                                continue
                        if sub != "" and not (sub in subs):
                                continue
                if age != "" and str(row.get("age", 3)) != age:
                        continue
                if content != "":
                        var cons: Array = (row.get("content", []) as Array).map(func(t): return String(t).to_lower())
                        if not (content in cons):
                                continue
                out.append(row)
        match sort:
                "size_up":
                        out.sort_custom(func(a, b): return float(a.get("size", 0)) < float(b.get("size", 0)))
                "size_down":
                        out.sort_custom(func(a, b): return float(a.get("size", 0)) > float(b.get("size", 0)))
                "date_up":
                        out.sort_custom(func(a, b): return String(a.get("updated", "")) < String(b.get("updated", "")))
                "date_down":
                        out.sort_custom(func(a, b): return String(a.get("updated", "")) > String(b.get("updated", "")))
                "version_up":
                        out.sort_custom(func(a, b): return int(a.get("versions_count", 1)) < int(b.get("versions_count", 1)))
                "version_down":
                        out.sort_custom(func(a, b): return int(a.get("versions_count", 1)) > int(b.get("versions_count", 1)))
        return out

# ------------------------------------------------------------- the download

## THE DOWNLOAD: fetch every file the index's manifest lists (raw http or
## a local copy), assemble the package in .cache, validate, install.
##   {"files": [{"path": "..."}, ...]}  - the index IS the manifest.
## Returns the import report + the honest why.
static func download(row: Dictionary) -> Dictionary:
        var report := {"installed": [], "skipped": [], "refused": [], "why": ""}
        var base := String(row.get("base_url", ""))
        var pkg_id := String(row.get("pkg_id", ""))
        if base == "" or pkg_id == "":
                report["why"] = "the row carries no source address"
                return report
        var g := _goga()
        if g == null:
                report["why"] = "the GOGA runtime is not up"
                return report
        # the already-installed honesty (the update law)
        var installed := installed_map()
        if installed.has(pkg_id):
                var cmp := _vcmp(String(row.get("version", "0")), String(installed[pkg_id]))
                if cmp <= 0:
                        report["why"] = "already installed" if cmp == 0 \
                                else "installed version %s is newer" % String(installed[pkg_id])
                        return report
        # the manifest: the index again - this time for its files list
        var idx_txt: String
        if bool(row.get("local", false)):
                idx_txt = FileAccess.get_file_as_string(base.path_join("index/index.json"))
        else:
                idx_txt = await http_get(base.path_join("index/index.json"))
        var parsed: Variant = JSON.parse_string(idx_txt)
        if not (parsed is Dictionary):
                report["why"] = "the game index could not be fetched"
                return report
        var idx: Dictionary = parsed
        var files: Array = idx.get("files", [])
        if files.is_empty():
                report["why"] = "the index carries no files manifest - nothing to download"
                return report
        # assemble in .cache
        var staging: String = String(g.call("cache_dir")).path_join("discover")
        var tmp := staging.path_join("dl").path_join(pkg_id)
        _rmdir(tmp)
        var fetched := 0
        for f in files:
                var fd: Dictionary = f
                var rel := String(fd.get("path", ""))
                if rel == "" or rel.contains(".."):
                        continue
                var dest := tmp.path_join(rel)
                DirAccess.make_dir_recursive_absolute(dest.get_base_dir())
                if bool(row.get("local", false)):
                        var src := base.path_join(rel)
                        if FileAccess.file_exists(src):
                                var da := DirAccess.open(dest.get_base_dir())
                                if da != null:
                                        da.copy(src, dest)
                                        fetched += 1
                        continue
                var data := await http_get_bytes("%s/%s" % [base, rel])
                if data.is_empty():
                        report["why"] = "the file %s answered nothing" % rel
                        return report
                var fw := FileAccess.open(dest, FileAccess.WRITE)
                if fw == null:
                        report["why"] = "cannot stage %s (disk or permission)" % rel
                        return report
                fw.store_buffer(data)
                fw.close()
                fetched += 1
        if fetched == 0:
                report["why"] = "not one file of the manifest arrived"
                return report
        # validate + install through the SAME door a local import uses -
        # the local flow IS the contract (the local simulation law)
        var v: Dictionary = g.call("validate_root", tmp)
        if not bool(v["ok"]):
                report["why"] = "the downloaded package failed the strict validator"
                report["refused"] = v["errors"]
                _rmdir(tmp)
                return report
        var imp: Dictionary = g.call("import_path", tmp)
        _rmdir(tmp)
        report["installed"] = imp["installed"]
        report["skipped"] = imp["skipped"]
        report["refused"] = imp["refused"]
        return report

static func _rmdir(path: String) -> void:
        if not DirAccess.dir_exists_absolute(path):
                return
        var da := DirAccess.open(path)
        if da != null:
                da.list_dir_begin()
                var n := da.get_next()
                while n != "":
                        var full := path.path_join(n)
                        if da.current_is_dir():
                                _rmdir(full)
                        else:
                                da.remove(n)
                        n = da.get_next()
                da.list_dir_end()
        DirAccess.remove_absolute(path)

## The update census: for every installed package, does any source carry a
## newer version? (the boot check + the settings schedule's engine seat)
static func check_updates() -> Dictionary:
        var feed := await fetch_feed()
        var updates: Array = []
        var installed := installed_map()
        for r in (feed["rows"] as Array):
                var row: Dictionary = r
                var pkg_id := String(row.get("pkg_id", ""))
                if not installed.has(pkg_id):
                        continue
                var cmp := _vcmp(String(row.get("version", "0")), String(installed[pkg_id]))
                if cmp > 0:
                        updates.append(row)
        return {"updates": updates, "rows": feed["rows"], "notes": feed["notes"]}
