extends Node

## Central HTTP helper for the Space Shooty backend.
## Registered as autoload "Api" in project.godot.
##
## Usage (from any scene):
##   var result = await Api.start_game(username)
##   var result = await Api.end_game(token, score)
##   var result = await Api.get_leaderboard(page)
##
## All functions return a Dictionary that always has an "ok" key:
##   { "ok": true, ... }   on success
##   { "ok": false, "error": "..." }   on any failure


const BASE_URL := "http://127.0.0.1:3000"


func _make_request(method: HTTPClient.Method, endpoint: String, body: Dictionary = {}) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = 5.0
	add_child(http)

	var headers := PackedStringArray([
		"Content-Type: application/json",
		"Accept: application/json",
	])
	var body_str := JSON.stringify(body) if not body.is_empty() else ""

	var err := http.request(BASE_URL + endpoint, headers, method, body_str)
	if err != OK:
		http.queue_free()
		return { "ok": false, "error": "Failed to send request (err %d)" % err }

	# request_completed emits: (result, response_code, headers, body)
	var response: Array = await http.request_completed
	http.queue_free()

	var net_result: int = response[0]
	var status_code: int = response[1]
	var body_bytes: PackedByteArray = response[3]

	if net_result != HTTPRequest.RESULT_SUCCESS:
		return { "ok": false, "error": "Network error (result %d)" % net_result }

	var json := JSON.new()
	if json.parse(body_bytes.get_string_from_utf8()) != OK:
		return { "ok": false, "error": "Invalid server response" }

	var data = json.get_data()
	if not data is Dictionary:
		return { "ok": false, "error": "Unexpected response format" }

	if status_code >= 200 and status_code < 300:
		data["ok"] = true
		return data
	else:
		return { "ok": false, "error": data.get("error", "Server error (%d)" % status_code) }


## POST /game/start — registers a new game session and returns a signed token.
func start_game(username: String) -> Dictionary:
	return await _make_request(
		HTTPClient.METHOD_POST,
		"/game/start",
		{ "username": username }
	)


## POST /game/end — submits the final score for the session.
## Returns { "ok": true, "rank": N } on success.
func end_game(token: String, score: int) -> Dictionary:
	return await _make_request(
		HTTPClient.METHOD_POST,
		"/game/end",
		{ "token": token, "score": score }
	)


## GET /leaderboard — returns a page of top scores.
## Returns { "ok": true, "scores": [...], "pagination": {...} }
func get_leaderboard(page: int = 1) -> Dictionary:
	return await _make_request(
		HTTPClient.METHOD_GET,
		"/leaderboard?page=%d&limit=20" % page
	)
