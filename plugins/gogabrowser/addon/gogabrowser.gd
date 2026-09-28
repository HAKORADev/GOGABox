extends Node
## GogaBrowser - the in-app WebView seat for GOGABox web games (v043 pass
## 3, WEB_GAMES.md realized). Native side: plugins/gogabrowser (Java,
## staged into the gradle build by .ci/materialize-project.sh). The
## GDScript side is the desktop/test no-op: on PC the web seat is the
## app-mode window (goga_runner.gd), in tests the singleton never exists
## and the runner refuses honestly.
##
##   var b = Engine.get_singleton("GogaBrowser")   # Android only
##   b.load_url(url); b.show_surface(); b.hide_surface()
##
## THE NO-TAB LAW: the surface is INSIDE the activity - no browser chrome,
## no tab, no redirection. The page's SDK bridge is sdk/web/goga_bridge.js
## over the box's WebSocket door (127.0.0.1:31443), the same file the PC
## app-mode window loads - one bridge, both seats.

func load_url(_url: String) -> bool:
        return false   # desktop/test: the honest no-op

func show_surface() -> bool:
        return false

func hide_surface() -> bool:
        return false

func is_visible() -> bool:
        return false
