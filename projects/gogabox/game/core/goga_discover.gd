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
# v043 pass 3 THE CATALOG SCHEMA 2 (the owner: "you literally made index/
# to be one file ... there should be really different files for each repos
# tier"): the source's index/ folder is a REAL catalog now - one file per
# repos tier beside the source manifest, and REPOS.txt stays the plain
# register the two-step publish PRs against. The engine walks the map;
# a schema-1 source (inline "games") still parses - old repos keep working.
#   GOGAs/discover/index/source.json     the identity + the tier file map
#   GOGAs/discover/index/official.json   the official tier's game rows
#   GOGAs/discover/index/community.json  the community source directory
#   GOGAs/discover/index/hobbyist.json   the hobbyist rows (usually empty)
const CATALOG_DIR := "GOGAs/discover/index"
const SCHEMA := 2
const RAW_HOST := "https://raw.githubusercontent.com"
# the community expansion is ONE hop deep, from the official source only -
# a community repo's own community.json does not fan out again (the feed
# stays bounded; the register is the official repo's voice, not a web).
const COMMUNITY_HOP := 1

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

## THE UPDATE LABEL LAW (the feed cards AND the page button share it):
##   no installed version  -> DOWNLOAD (alive)
##   older installed       -> UPDATE to vX (alive)
##   same version          -> INSTALLED (dead - the update law skips it)
##   newer local than src  -> INSTALLED (dead - the source is behind)
static func update_label(row: Dictionary) -> Dictionary:
        var installed := String(row.get("installed_version", ""))
        if installed == "":
                return {"txt": "DOWNLOAD", "dead": false}
        var cmp := _vcmp(String(row.get("version", "0")), installed)
        if cmp > 0:
                return {"txt": "UPDATE to v%s" % String(row.get("version", "")),
                                "dead": false}
        return {"txt": "INSTALLED", "dead": true}

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
        if not http.is_inside_tree():
                # a fetch asked during the tree's own setup window (a boot
                # probe, a test _ready) - the add_child above is refused;
                # one frame later it lands
                await _tree().process_frame
                root.add_child(http)
                if not http.is_inside_tree():
                        http.queue_free()
                        return PackedByteArray()
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
                        rows.append_array(await _feed_for_local(String(s.get("path", "")),
                                        community, installed_map(), notes))
        return {"rows": rows, "notes": notes}

## One github source's feed rows: fetch source.json, then walk the catalog.
## SCHEMA 2 (the catalog): source.json's "tiers" map names one file per
## repos tier under GOGAs/discover/index/ - official/hobbyist files carry
## game rows, the community file carries a DIRECTORY of sources that each
## get their own walk (one hop, from the official source only). SCHEMA 1
## (the old inline "games" array) still parses - existing repos keep
## working untouched.
## THE TIER TRUST LAW: rows from the OFFICIAL source wear the tier FILE's
## name (the owner curates his own catalog); rows from every other source
## wear the ENGINE's tier (tier_for) - a community repo can never claim
## official by listing its games in an official.json.
static func _feed_for_github(repo: String, branch: String, community: Array,
                installed: Dictionary, notes: Array, depth := 0) -> Array:
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
        var s: Dictionary = src
        var is_official := official_repo(repo)
        var tier := tier_for(repo, community)
        if int(s.get("schema", 1)) >= 2 and s.has("tiers") \
                        and (s["tiers"] is Dictionary):
                # ---- SCHEMA 2: the per-tier catalog files ----
                # the tier map paths are RELATIVE TO THE CATALOG FOLDER
                # (the files sit beside source.json); the game index paths
                # INSIDE the tier files are repo-relative (they point into
                # games/)
                var catalog_base := base.path_join(SOURCE_JSON.get_base_dir())
                # the game index paths inside the tier files are GOGAs-
                # folder-relative ("games/<pkg>/index/index.json" sits under
                # the repo's GOGAs/) - the SCHEMA 2 convention
                var goga_base := base.path_join("GOGAs")
                var tiers: Dictionary = s["tiers"]
                for tname in ["official", "community", "hobbyist"]:
                        var rel := String(tiers.get(tname, ""))
                        if rel == "":
                                continue
                        var ttxt := await http_get("%s/%s" % [catalog_base, rel])
                        if ttxt == "":
                                notes.append({"repo": repo,
                                                "why": "the tier file %s answered nothing" % rel})
                                continue
                        var tv: Variant = JSON.parse_string(ttxt)
                        if not (tv is Dictionary):
                                notes.append({"repo": repo,
                                                "why": "the tier file %s is not a JSON object" % rel})
                                continue
                        var tf: Dictionary = tv
                        if tname == "community":
                                # the community DIRECTORY: each listed source
                                # walks on its own (tier = the engine's law
                                # for that repo); one hop, from official only
                                if depth >= COMMUNITY_HOP or not is_official:
                                        continue
                                for cs in (tf.get("sources", []) as Array):
                                        var cd: Dictionary = cs
                                        var crepo := String(cd.get("repo", ""))
                                        if crepo == "" or OFFICIAL_REPOS.has(crepo):
                                                continue
                                        var cbranch := String(cd.get("branch", "main"))
                                        rows.append_array(await _feed_for_github(
                                                        crepo, cbranch, community,
                                                        installed, notes, depth + 1))
                        else:
                                var row_tier: String = tname if is_official else tier
                                rows.append_array(await _rows_from_tier_games(
                                                goga_base, tf.get("games", []), row_tier,
                                                repo, installed, notes, false))
                return rows
        # ---- SCHEMA 1: the inline games array (the old convention) ----
        for g in (s.get("games", []) as Array):
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
                rows.append(_make_row(e, gd, pkg_id, tier, repo, game_base,
                                installed, false))
        return rows

## The shared SCHEMA 2 walk: one tier file's "games" rows (raw URLs or
## local paths both land here; `local` flips the fetch doors).
static func _rows_from_tier_games(base: String, games: Array, row_tier: String,
                source_name: String, installed: Dictionary, notes: Array,
                local: bool) -> Array:
        var rows: Array = []
        for g in games:
                var gd: Dictionary = g
                var index_rel := String(gd.get("index", ""))
                if index_rel == "":
                        continue
                var itxt: String
                if local:
                        itxt = FileAccess.get_file_as_string(
                                        base.path_join(index_rel)) \
                                if FileAccess.file_exists(base.path_join(index_rel)) \
                                else ""
                else:
                        itxt = await http_get("%s/%s" % [base, index_rel])
                if itxt == "":
                        notes.append({"repo": source_name,
                                        "why": "game index %s answered nothing" % index_rel})
                        continue
                var idx: Variant = JSON.parse_string(itxt)
                if not (idx is Dictionary):
                        notes.append({"repo": source_name,
                                        "why": "game index %s is not a JSON object" % index_rel})
                        continue
                var e: Dictionary = idx
                var pkg_id := String(e.get("id", ""))
                var game_base: String
                if local:
                        game_base = base.path_join(index_rel.trim_suffix("index/index.json"))
                else:
                        game_base = "%s/%s" % [base, index_rel.trim_suffix("index/index.json")]
                rows.append(_make_row(e, gd, pkg_id, row_tier, source_name,
                                game_base, installed, local))
        return rows

## One feed row from a game's index.json (+ the tier row's fast metadata).
static func _make_row(e: Dictionary, gd: Dictionary, pkg_id: String, tier: String,
                source_name: String, game_base: String, installed: Dictionary,
                local: bool) -> Dictionary:
        var row := {
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
                "versions_count": int(e.get("versions_count", gd.get("versions_count", 1))),
                "tier": tier,
                "source": source_name,
                "desc": String(e.get("desc", "")),
                "base_url": game_base,
                "installed_version": String(installed.get(pkg_id, "")),
        }
        if local:
                row["thumb_path"] = game_base.path_join(String(e.get("thumb", "")))
                row["local"] = true
        else:
                row["thumb_url"] = "%s%s" % [game_base, String(e.get("thumb", ""))]
        return row

## One LOCAL source's feed rows: a folder root, a parent of roots, or a
## virtual repo (gogabox.repo.json marks the root of the simulation).
## v043 pass 3 THE FULL SIMULATION: a folder shaped like a repo (carrying
## GOGAs/discover/index/source.json) walks the SCHEMA 2 catalog exactly
## like the github flow - the local developer has tested the real thing.
static func _feed_for_local(path: String, community: Array,
                installed: Dictionary, notes: Array) -> Array:
        var rows: Array = []
        if not DirAccess.dir_exists_absolute(path):
                notes.append({"repo": path, "why": "the local source folder does not exist"})
                return rows
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
        # ---- the repo-shaped walk (the SCHEMA 2 catalog, local doors) ----
        # the catalog sits at <root>/GOGAs/discover/index when the source
        # points at a REPO root, or at <root>/discover/index when it points
        # at the GOGAs folder itself (the tree next to the exe) - both are
        # the same catalog, one folder apart
        var catalog := path.path_join(CATALOG_DIR)
        if not FileAccess.file_exists(catalog.path_join("source.json")):
                catalog = path.path_join("discover/index")
        if FileAccess.file_exists(catalog.path_join("source.json")):
                var stxt := FileAccess.get_file_as_string(
                                catalog.path_join("source.json"))
                var sv: Variant = JSON.parse_string(stxt)
                if sv is Dictionary and int((sv as Dictionary).get("schema", 1)) >= 2 \
                                and ((sv as Dictionary).get("tiers", {}) is Dictionary):
                        var s: Dictionary = sv
                        var tiers: Dictionary = s["tiers"]
                        for tname in ["official", "hobbyist"]:
                                var rel := String(tiers.get(tname, ""))
                                if rel == "":
                                        continue
                                var tf_path := catalog.path_join(rel)
                                if not FileAccess.file_exists(tf_path):
                                        continue
                                var tv: Variant = JSON.parse_string(
                                                FileAccess.get_file_as_string(tf_path))
                                if not (tv is Dictionary):
                                        continue
                                var row_tier: String = tname if tier == "official" else tier
                                # the tier files' game paths are relative to
                                # the GOGAs FOLDER: two levels up from the
                                # catalog (repo-root sources and GOGAs-folder
                                # sources both land right)
                                var goga_base := catalog.get_base_dir().get_base_dir()
                                rows.append_array(await _rows_from_tier_games(goga_base,
                                                (tv as Dictionary).get("games", []),
                                                row_tier,
                                                repo_name if repo_name != "" else "local:" + path,
                                                installed, notes, true))
                        return rows
        # ---- the plain package walk (folder root / parent of roots) ----
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
        for root in roots:
                var itxt := FileAccess.get_file_as_string(root.path_join("index/index.json"))
                var idx: Variant = JSON.parse_string(itxt)
                if not (idx is Dictionary):
                        notes.append({"repo": root, "why": "the local index is not a JSON object"})
                        continue
                var e: Dictionary = idx
                var pkg_id := String(e.get("id", ""))
                # a plain folder's size is measured on the spot (the index
                # may not carry size_bytes)
                rows.append(_make_row(e, {"size_bytes": _dir_size(root)},
                                pkg_id, tier,
                                repo_name if repo_name != "" else "local:" + path,
                                root, installed, true))
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
        # THE LOWERCASE LAW (the owner: "if someone wrote BOarD or boARd, all
        # will lead to same genre/sub-genre"): the FILTER VALUE normalizes
        # too - the data side is normalized below, the filter meets it there
        var gq := genre.to_lower()
        var sq := sub.to_lower()
        var cq := content.to_lower()
        var tq := tier.to_lower()
        for r in rows:
                var row: Dictionary = r
                if tq != "" and String(row.get("tier", "")) != tq:
                        continue
                if q != "" and not (q in (String(row.get("title", "")) + " " + String(row.get("pkg_id", ""))).to_lower().replace(" ", "")):
                        continue
                if gq != "" or sq != "":
                        var geo: Dictionary = row.get("genres", {})
                        var mains: Array = (geo.get("main", []) as Array).map(func(t): return String(t).to_lower())
                        var subs: Array = (geo.get("sub", []) as Array).map(func(t): return String(t).to_lower())
                        if gq != "" and not (gq in mains):
                                continue
                        if sq != "" and not (sq in subs):
                                continue
                if age != "" and str(row.get("age", 3)) != age:
                        continue
                if cq != "":
                        var cons: Array = (row.get("content", []) as Array).map(func(t): return String(t).to_lower())
                        if not (cq in cons):
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
