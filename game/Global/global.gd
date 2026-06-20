extends Node

var score: int = 0           # seconds survived; written by ui.gd every second
var session_token: String = ""  # JWT from /game/start; cleared after /game/end
var username: String = ""    # set by the player in the start menu

# Flyons balance and upgrade levels live in the Upgrades autoload (Global/upgrades.gd).
# Do not add them here — keep Global to score/token/username only.

func save_username(name: String) -> void:
	username = name
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var js = Engine.get_singleton("JavaScriptBridge")
		js.eval("localStorage.setItem('space_shooty_username', %s)" % JSON.stringify(name))

## Load a previously saved username. Returns empty string if none found.
func load_username() -> String:
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var js = Engine.get_singleton("JavaScriptBridge")
		var result = js.eval("localStorage.getItem('space_shooty_username') || ''")
		# js.eval can return a Variant null on first run — guard before is-check
		if result != null and result is String and result.length() > 0:
			username = result
	# username is typed String with default "", so this is always safe
	return username if username is String else ""
