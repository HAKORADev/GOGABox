extends Node
## Notify - local notification bridge for GOGABox (Android).
## Native side: plugins/notify (Java, staged into the gradle build by
## .ci/materialize-project.sh). On desktop every call is a no-op so the box
## and the headless tests run unchanged.
##
##   Notify.schedule(1001, "GOGABox", "Dario is ready!", 3600, "game_ready")
##   Notify.cancel(1001)
##
## Scheduling is persisted natively (survives reboot + process death) via
## AlarmManager, so timed game reveals fire even days later.
##
## MODULAR NOTIFICATION SOUNDS: every notification carries a KIND, and each
## kind owns (a) its own Android notification CHANNEL with a custom sound
## (raw resources notify_battery/notify_ready/notify_general) and (b) an
## in-app SFX played through Jukebox when the event happens live. Adding a
## new kind = one entry in KINDS below + one raw wav. Nothing else.

## kind -> {channel: android channel id, sfx: Jukebox name}
const KINDS := {
        "general": {"channel": "gogabox_general_v2", "sfx": "general"},
        "battery_full": {"channel": "gogabox_battery_v2", "sfx": "battery_full"},
        "game_ready": {"channel": "gogabox_ready_v2", "sfx": "game_ready"},
}

var native: Object = null

func _ready() -> void:
        if OS.has_feature("android") and Engine.has_singleton("Notify"):
                native = Engine.get_singleton("Notify")
                print("Notify: native plugin attached")

func available() -> bool:
        return native != null

func permission_granted() -> bool:
        if native == null:
                return false
        return native.permission_granted()

## Ask Android 13+ for POST_NOTIFICATIONS (no-op below 33 / on desktop).
func request_permission() -> void:
        if native != null:
                native.request_permission()

func channel_for(kind: String) -> String:
        return String(KINDS.get(kind, KINDS["general"])["channel"])

## In-app SFX for a live event (battery hit full, game revealed, ...).
## Desktop-safe: Jukebox no-ops when the stream does not exist.
func play_kind_sfx(kind: String) -> void:
        var sfx_name := String(KINDS.get(kind, KINDS["general"])["sfx"])
        Jukebox.sfx(sfx_name, -2.0)

## Fire a local notification after delay_sec. id must be a stable int
## (use Roadmap._notify_id(game_id)) so the same reveal can be re-scheduled.
## kind picks the sound/channel (see KINDS above).
func schedule(id: int, title: String, body: String, delay_sec: int, kind := "general") -> void:
        if native != null:
                native.schedule_kind(id, title, body, delay_sec, channel_for(kind))
        else:
                print("Notify(sim): [%d] in %ds - %s | %s (%s)" % [id, delay_sec, title, body, kind])

func cancel(id: int) -> void:
        if native != null:
                native.cancel(id)

func cancel_all() -> void:
        if native != null:
                native.cancel_all()
