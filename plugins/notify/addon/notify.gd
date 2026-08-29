extends Node
## Notify - local notification bridge for GOGABox (Android).
## Native side: plugins/notify (Java, staged into the gradle build by
## .ci/materialize-project.sh). On desktop every call is a no-op so the box
## and the headless tests run unchanged.
##
##   Notify.schedule(1001, "GOGABox", "Dario is ready!", 3600)
##   Notify.cancel(1001)
##
## Scheduling is persisted natively (survives reboot + process death) via
## AlarmManager, so timed game reveals fire even days later.

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

## Fire a local notification after delay_sec. id must be a stable int
## (use Roadmap._notify_id(game_id)) so the same reveal can be re-scheduled.
func schedule(id: int, title: String, body: String, delay_sec: int) -> void:
	if native != null:
		native.schedule(id, title, body, delay_sec)
	else:
		print("Notify(sim): [%d] in %ds - %s | %s" % [id, delay_sec, title, body])

func cancel(id: int) -> void:
	if native != null:
		native.cancel(id)

func cancel_all() -> void:
	if native != null:
		native.cancel_all()
