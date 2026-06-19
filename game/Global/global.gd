extends Node

var score: int = 0
var session_token: String = ""
var username: String = ""

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
