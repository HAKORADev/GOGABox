extends Node
## Notify - local notification bridge for GOGABox (Android + WINDOWS).
## Native side: plugins/notify (Java, staged into the gradle build by
## .ci/materialize-project.sh). On WINDOWS the box now fires REAL toast
## notifications (v041-1 r7, the owner: "windows 10 non-windows-store
## normal apps can send notifications, so make GOGABox windows build be
## 1:1 the same as the android one ... same way we control title/content/
## icon/sound in android for a notification"). Headless/tests: the sim
## print, unchanged.
##
##   Notify.schedule(1001, "GOGABox", "Dario is ready!", 3600, "game_ready")
##   Notify.cancel(1001)
##
## Android: scheduling is persisted natively (survives reboot + process
## death) via AlarmManager, so timed game reveals fire even days later.
## Windows: the same call registers a REAL Scheduled Task that fires a
## WinRT toast at the same second - it survives the app closing AND a
## reboot, the exact AlarmManager contract. The toast wears the box's own
## identity: a per-user AppUserModelId registration (HKCU) carries the
## DisplayName + icon (the taskbar-adjacent attribution face), the toast
## XML carries the title, the body and the icon image, and each KIND maps
## to its own toast sound - the per-kind channel law, the Windows way.
## Adding a new kind = one entry in KINDS + one raw wav (Android) + one
## entry in WIN_AUDIO (Windows). Nothing else.
##
## MODULAR NOTIFICATION SOUNDS: every notification carries a KIND, and
## each kind owns (a) its own Android notification CHANNEL with a custom
## sound (raw resources notify_battery/notify_ready/notify_general) and
## (b) an in-app SFX played through Jukebox when the event happens live.

## kind -> {channel: android channel id, sfx: Jukebox name}
## v0.1.2: channel ids bumped v2 -> v3. Channels are immutable on the
## device, so the only cure for a silent legacy channel state (the owner's
## silent batteries notification) is FRESH ids; the Java side deletes the
## v2 ids + migrates pending schedules on upgrade.
const KINDS := {
        "general": {"channel": "gogabox_general_v3", "sfx": "general"},
        "battery_full": {"channel": "gogabox_battery_v3", "sfx": "battery_full"},
        "game_ready": {"channel": "gogabox_ready_v3", "sfx": "game_ready"},
}

## v041-1 r7 THE WINDOWS SOUND LAW: custom wav audio in toasts is a
## packaged-app feature; unpackaged desktop toasts speak the system's
## toast sound family - so each kind maps to a DISTINCT winsoundevent,
## the honest 1:1 of the Android per-kind channels (the kind still picks
## the sound; the library of voices is the OS's own).
const WIN_AUDIO := {
        "general": "ms-winsoundevent:Notification.Default",
        "battery_full": "ms-winsoundevent:Notification.IM",
        "game_ready": "ms-winsoundevent:Notification.Mail",
}
const WIN_AUMID := "HAKORA.GOGABox"
const WIN_TASK_PREFIX := "GOGABoxNotify_"

var native: Object = null

# ---- the Windows seat (all paths under user://, all writes idempotent)
var _win := false
var _win_dir := ""
var _win_icon := ""
var _win_fire := ""
var _win_sched := ""

func _ready() -> void:
        if OS.has_feature("android") and Engine.has_singleton("Notify"):
                native = Engine.get_singleton("Notify")
                print("Notify: native plugin attached")
        # v041-1 r7: the Windows toast seat - scripts + icon + the AUMID
        # registration, all fire-and-forget, never on the boot path.
        if OS.has_feature("windows") and DisplayServer.get_name() != "headless":
                _win_setup()

func available() -> bool:
        return native != null or _win

func permission_granted() -> bool:
        if native != null:
                return native.permission_granted()
        # Windows: an unpackaged app has no per-app permission API - the
        # OS delivers unless the user mutes the app in Settings (the AUMID
        # registration with ShowInSettings gives it that page). Honest
        # default: deliverable.
        return _win

## Ask Android 13+ for POST_NOTIFICATIONS (no-op below 33 / on desktop).
## v0.1.0: names now match the Java methods EXACTLY (Godot does no
## snake_case/camelCase conversion - that mismatch silently killed every
## permission call in v0.0.6..v0.0.9). This is the plain official ask:
## the real system dialog, nothing else.
func request_permission() -> void:
        if native != null:
                print("[Notify] request_permission -> native")
                native.request_permission()

## Jump straight to this app's system notification settings (user flips the
## toggle by hand). Desktop: no-op.
func open_notification_settings() -> void:
        if native != null:
                native.open_notification_settings()

func channel_for(kind: String) -> String:
        return String(KINDS.get(kind, KINDS["general"])["channel"])

## In-app SFX for a live event (battery hit full, game revealed, ...).
## Desktop-safe: Jukebox no-ops when the stream does not exist.
func play_kind_sfx(kind: String) -> void:
        var sfx_name := String(KINDS.get(kind, KINDS["general"])["sfx"])
        Jukebox.sfx(sfx_name, -2.0)

## Fire a local notification after delay_sec. id must be a stable int
## (use Roadmap._notify_id(game_id)) so the same reveal can be re-scheduled.
## kind picks the sound/channel (see KINDS above; WIN_AUDIO on Windows).
func schedule(id: int, title: String, body: String, delay_sec: int, kind := "general") -> void:
        if native != null:
                native.schedule_kind(id, title, body, delay_sec, channel_for(kind))
        elif _win:
                _win_schedule(id, title, body, delay_sec, kind)
        else:
                print("Notify(sim): [%d] in %ds - %s | %s (%s)" % [id, delay_sec, title, body, kind])

func cancel(id: int) -> void:
        if native != null:
                native.cancel(id)
        elif _win:
                _win_cancel(id)

func cancel_all() -> void:
        if native != null:
                native.cancel_all()
        elif _win:
                _win_cancel_all()

# ======================================= v041-1 r7 THE WINDOWS TOAST SEAT
## The owner's order: the Windows build notifies 1:1 with Android - same
## entries (schedule/cancel/cancel_all), same controllables (title,
## content, icon, per-kind sound). The road (all per-user, no admin, no
## dependencies):
##   - THE IDENTITY: HKCU\Software\Classes\AppUserModelId\HAKORA.GOGABox
##     carries DisplayName "GOGABox" + the box icon + ShowInSettings, so
##     the toast attributes itself to GOGABox and the app gets its own
##     page in Windows' notification settings (the Android channel's
##     Settings face).
##   - THE CLOCK: a real Scheduled Task per notification (GOGABoxNotify_<id>)
##     fires powershell at the exact second - it survives the app closing
##     AND a reboot, the AlarmManager contract. -Force re-registration
##     makes reschedules idempotent; Unregister is the cancel.
##   - THE TOAST: fire.ps1 builds a ToastNotification from the per-id XML
##     (ToastGeneric: title, body, the icon as appLogoOverride, the kind's
##     sound in <audio>) and shows it under OUR AUMID.
## Everything is written under user://notify at first use; the icon is
## exported there from the PCK (a toast needs a REAL file path).
const WIN_FIRE_PS1 := """param([string]$XmlPath)
try {
    $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime]
    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml([System.IO.File]::ReadAllText($XmlPath))
    $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('%AUMID%').Show($toast)
} catch { }
"""
const WIN_SCHED_PS1 := """param([string]$TaskName, [int]$DelaySec, [string]$XmlPath, [string]$FireScript, [string]$IconPath)
$ErrorActionPreference = 'Stop'
try {
    $k = 'HKCU:\\Software\\Classes\\AppUserModelId\\%AUMID%'
    if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
    Set-ItemProperty -Path $k -Name 'DisplayName' -Value 'GOGABox'
    Set-ItemProperty -Path $k -Name 'CustomIcon' -Value $IconPath
    Set-ItemProperty -Path $k -Name 'ShowInSettings' -Value 1
    $t = [DateTime]::UtcNow.AddSeconds($DelaySec)
    $arg = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $FireScript + '" -XmlPath "' + $XmlPath + '"'
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arg
    $trigger = New-ScheduledTaskTrigger -Once -At $t
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopOnIdleEnd
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
    exit 0
} catch { exit 1 }
"""

func _win_setup() -> void:
        _win = true
        _win_dir = OS.get_user_data_dir().path_join("notify")
        DirAccess.make_dir_recursive_absolute(_win_dir)
        _win_icon = _win_dir.path_join("icon.png")
        _win_fire = _win_dir.path_join("fire.ps1")
        _win_sched = _win_dir.path_join("sched.ps1")
        # the icon: a toast needs a REAL file - export the canonical face
        # from the PCK once (the same icon the window wears at boot)
        if not FileAccess.file_exists(_win_icon):
                var tex := load("res://icons/main_512x512.png")
                if tex != null and tex.get_image() != null:
                        var img: Image = tex.get_image()
                        if img.is_compressed():
                                img.decompress()
                        img.save_png(_win_icon)
        _write_text(_win_fire, WIN_FIRE_PS1.replace("%AUMID%", WIN_AUMID))
        _write_text(_win_sched, WIN_SCHED_PS1.replace("%AUMID%", WIN_AUMID))
        # the identity registration at boot too (idempotent reg adds, fire-
        # and-forget): the box appears in Windows' notification settings even
        # before the first toast fires
        var base := "HKCU\\Software\\Classes\\AppUserModelId\\" + WIN_AUMID
        _win_spawn("reg", ["add", base, "/v", "DisplayName", "/t", "REG_SZ",
                        "/d", "GOGABox", "/f"])
        _win_spawn("reg", ["add", base, "/v", "CustomIcon", "/t", "REG_SZ",
                        "/d", _win_icon, "/f"])
        _win_spawn("reg", ["add", base, "/v", "ShowInSettings", "/t", "REG_DWORD",
                        "/d", "1", "/f"])

func _write_text(path: String, txt: String) -> void:
        var f := FileAccess.open(path, FileAccess.WRITE)
        if f != null:
                f.store_string(txt)
                f.close()

func _win_spawn(exe: String, args: PackedStringArray) -> void:
        OS.create_process(exe, args, false)

## THE XML (pure - probes assert on it): ToastGeneric wears the title,
## the body, the icon and the kind's sound. XML-escaped like Android's
## strings are.
func _win_toast_xml(title: String, body: String, kind: String) -> String:
        var sound := String(WIN_AUDIO.get(kind, WIN_AUDIO["general"]))
        return "<toast><visual><binding template=\"ToastGeneric\">" \
                        + "<text>%s</text><text>%s</text>" \
                                        % [_xml_esc(title), _xml_esc(body)] \
                        + "<image placement=\"appLogoOverride\" src=\"%s\" hint-crop=\"none\"/>" \
                                        % _xml_esc(_win_icon) \
                        + "</binding></visual><audio src=\"%s\"/></toast>" % sound

static func _xml_esc(s: String) -> String:
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;") \
                        .replace("\"", "&quot;").replace("'", "&apos;")

func _win_schedule(id: int, title: String, body: String, delay_sec: int,
                        kind: String) -> void:
        var xml_path := _win_dir.path_join("toast_%d.xml" % id)
        _write_text(xml_path, _win_toast_xml(title, body, kind))
        # a minimum lead so a task never fires "in the past" on slow machines
        var secs := maxi(5, delay_sec)
        _win_spawn("powershell", PackedStringArray([
                        "-NoProfile", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden",
                        "-File", _win_sched,
                        "-TaskName", WIN_TASK_PREFIX + str(id),
                        "-DelaySec", str(secs),
                        "-XmlPath", xml_path,
                        "-FireScript", _win_fire,
                        "-IconPath", _win_icon,
                ]))

func _win_cancel(id: int) -> void:
        _win_spawn("powershell", PackedStringArray([
                        "-NoProfile", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden",
                        "-Command", "Unregister-ScheduledTask -TaskName '%s%d' -Confirm:$false -ErrorAction SilentlyContinue; exit 0"
                                        % [WIN_TASK_PREFIX, id],
                ]))
        var f := _win_dir.path_join("toast_%d.xml" % id)
        if FileAccess.file_exists(f):
                DirAccess.remove_absolute(f)

func _win_cancel_all() -> void:
        _win_spawn("powershell", PackedStringArray([
                        "-NoProfile", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden",
                        "-Command", "Get-ScheduledTask -TaskName '%s*' -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false; exit 0"
                                        % WIN_TASK_PREFIX,
                ]))
