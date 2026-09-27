class_name GogaUpdate
extends RefCounted
## THE APP SELF-UPDATE ENGINE (v043 - the owner's "tricks of updating the
## app like for android where it uses the android package installer after
## asking for that permission and windows for replace the file after close
## and notifying user to close when ready").
##
## The version channel rides the OFFICIAL discover source (raw http, zero
## API): GOGAs/discover/index/source.json carries
##   "engine_version": "0.4.3"          - the engine the source serves
##   "update_assets": {"android": "<url>", "pc": "<url>"}
## The URLs point at the release download (github release assets are
## plain https - no API, the no-api-limit law holds).
##
## THE PLATFORM TRICKS:
##   Android - the apk lands in GOGAs/.cache/update/ and the package
##     installer seat opens it (REQUEST_INSTALL_PACKAGES rides the
##     manifest; the honest refusal names the missing permission when the
##     user said no).
##   Windows - the new exe lands in GOGAs/.cache/update/, an apply.cmd
##     helper is written (wait for close -> replace -> restart), the box
##     spawns it detached and tells the user to close when ready. THE
##     REPLACE-AFTER-CLOSE LAW: nothing touches a running exe.

const UPDATE_DIR := "update"

# ------------------------------------------------------------- the census

## The engine seat: {available, current, served, url} or honest reasons.
static func check() -> Dictionary:
        var out := {"available": false, "current": "", "served": "", "url": ""}
        var repo: String = GogaDiscover.OFFICIAL_REPOS[0]
        var url := "%s/%s/main/%s" % [GogaDiscover.RAW_HOST, repo,
                        GogaDiscover.SOURCE_JSON]
        var txt := await GogaDiscover.http_get(url)
        if txt == "":
                out["why"] = "the official source answered nothing"
                return out
        var v: Variant = JSON.parse_string(txt)
        if not (v is Dictionary):
                out["why"] = "the official source is not a JSON object"
                return out
        var s: Dictionary = v
        var served := String(s.get("engine_version", ""))
        var g := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("GOGA")
        var current: String = "dev"
        if g != null:
                current = String(g.call("self_version"))
        elif ProjectSettings.has_setting("application/config/version"):
                current = String(ProjectSettings.get_setting("application/config/version"))
        out["current"] = current
        out["served"] = served
        if served == "" or current == "dev":
                out["why"] = "the version channel is quiet (dev build or no version served)"
                return out
        var assets: Dictionary = s.get("update_assets", {})
        var plat := "android" if OS.has_feature("android") else "pc"
        out["url"] = String(assets.get(plat, ""))
        if out["url"] == "":
                out["why"] = "the source serves no %s asset" % plat
                return out
        out["available"] = _vcmp(served, current) > 0
        return out

static func _vcmp(a: String, b: String) -> int:
        var g := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("GOGA")
        if g != null:
                return int(g.call("version_compare", a, b))
        return 0

# ------------------------------------------------------------- the download

## Download the update asset into GOGAs/.cache/update/. Returns the file
## path or "" with the honest why inside {path, why}.
static func download(census: Dictionary) -> Dictionary:
        var out := {"path": "", "why": ""}
        if not bool(census.get("available", false)):
                out["why"] = "no update available"
                return out
        var g := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("GOGA")
        if g == null:
                out["why"] = "the GOGA runtime is not up"
                return out
        var dir := String(g.call("cache_dir")).path_join(UPDATE_DIR)
        DirAccess.make_dir_recursive_absolute(dir)
        var fname := "gogabox_update.apk" if OS.has_feature("android") \
                        else "GOGABox_update.zip"
        var dest := dir.path_join(fname)
        var bytes := await GogaDiscover.http_get_bytes(String(census["url"]), 300.0)
        if bytes.is_empty():
                out["why"] = "the update asset answered nothing"
                return out
        var f := FileAccess.open(dest, FileAccess.WRITE)
        if f == null:
                out["why"] = "cannot stage the update (disk or permission)"
                return out
        f.store_buffer(bytes)
        f.close()
        out["path"] = dest
        return out

# ------------------------------------------------------------- the applies

## ANDROID: open the staged apk through the package installer seat. The
## REQUEST_INSTALL_PACKAGES permission rides the manifest; the OS shows
## its own confirm sheet. Godot's shell_open routes the file to the
## system's installer handling; the honest why covers the refusals.
static func apply_android(path: String) -> Dictionary:
        var out := {"ok": false, "why": ""}
        if not OS.has_feature("android"):
                out["why"] = "not an android seat"
                return out
        if path == "" or not FileAccess.file_exists(path):
                out["why"] = "no staged update to apply"
                return out
        # OS.request_permission("android.permission.REQUEST_INSTALL_PACKAGES")
        # asks at use-time (the box's permission law: never at boot)
        var granted: bool = OS.request_permission("android.permission.REQUEST_INSTALL_PACKAGES")
        if not granted:
                out["why"] = "install-permission denied - allow it in the system settings and try again"
                return out
        var ok := OS.shell_open(path) == OK
        out["ok"] = ok
        if not ok:
                out["why"] = "the system refused the installer hand-off"
        return out

## WINDOWS: write apply.cmd (wait for close -> replace -> restart). The
## spawn is the caller's seat - THE REPLACE-AFTER-CLOSE LAW: nothing
## touches a running exe, the user closes when ready.
static func write_windows_helper(path: String) -> String:
        var dir := path.get_base_dir()
        var cmd := dir.path_join("apply_update.cmd")
        var exe := OS.get_executable_path()
        var f := FileAccess.open(cmd, FileAccess.WRITE)
        if f == null:
                return ""
        # the batch vars: the staged file, the exe target, the image name
        f.store_string("@set STAGE=" + path + "\r\n")
        f.store_string("@set EXE=" + exe + "\r\n")
        f.store_string("@set EXENAME=" + exe.get_file() + "\r\n")
        var script := "@echo off\r\n"
        script += "echo Waiting for GOGABox to close...\r\n"
        script += ":wait\r\n"
        script += "tasklist /FI \"IMAGENAME eq %EXENAME%\" 2>NUL | find /I \"%EXENAME%\" >NUL\r\n"
        script += "if \"%ERRORLEVEL%\"==\"0\" (\r\n  timeout /t 2 /nobreak >NUL\r\n  goto wait\r\n)\r\n"
        script += "echo Applying the update...\r\n"
        script += "copy /Y \"%STAGE%\" \"%EXE%\" >NUL\r\n"
        script += "if not \"%ERRORLEVEL%\"==\"0\" (\r\n  echo Replace failed - apply it by hand: %STAGE%\r\n  pause\r\n  exit /b 1\r\n)\r\n"
        script += "echo Done - restarting.\r\n"
        script += "start \"\" \"%EXE%\"\r\n"
        script += "exit /b 0\r\n"
        f.store_string(script)
        f.close()
        return cmd

## WINDOWS: write the helper, spawn it detached, tell the player.
static func apply_windows(path: String) -> Dictionary:
        var out := {"ok": false, "why": ""}
        if OS.has_feature("android"):
                out["why"] = "not a pc seat"
                return out
        if path == "" or not FileAccess.file_exists(path):
                out["why"] = "no staged update to apply"
                return out
        var cmd := write_windows_helper(path)
        if cmd == "":
                out["why"] = "cannot write the apply helper"
                return out
        # detached spawn - the helper outlives the box
        var pid := OS.create_process("cmd.exe", ["/c", cmd], true)
        if pid <= 0:
                out["why"] = "could not spawn the apply helper"
                return out
        out["ok"] = true
        return out

# ------------------------------------------------------------- the schedule

## THE UPDATE SCHEDULE (the settings' engine seat): a boot check + a
## periodic re-check. The menu owns the timer; these carry the cadence.
const CHECK_ON_BOOT := true
const CHECK_INTERVAL_HOURS := 24

static func should_check() -> bool:
        var box := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Box")
        if box == null:
                return false
        var last := int(box.call("get_meta_dict", "update_check").get("last_ts", 0))
        var now := int(Time.get_unix_time_from_system())
        return now - last >= CHECK_INTERVAL_HOURS * 3600

static func mark_checked() -> void:
        var box := (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Box")
        if box != null:
                var m: Dictionary = box.call("get_meta_dict", "update_check")
                m["last_ts"] = int(Time.get_unix_time_from_system())
                box.call("set_meta_dict", "update_check", m)
