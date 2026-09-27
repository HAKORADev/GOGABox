@tool
extends EditorPlugin
## GOGABox SDK plugin - enables the addon and hints the autoload seat.
## The developer adds "GogaSdk" as an autoload (see sdk/README.md) or the
## game calls GogaSdkSdk.new() directly; the plugin's job is discovery +
## editor hints (the unity-ads-shaped seat the platform doc ordered).

func _enter_tree() -> void:
        print("[GOGABox SDK] addon enabled - see developers/catalog/SDK.md")

func _exit_tree() -> void:
        pass
