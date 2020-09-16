extends Node

signal result_entered
signal entries_received(entries)
var login_http_request := HTTPRequest.new()

const SERVICE_ENVIRONMENTS = {
	"live": "http://localhost:8000",
	"dev": "http://localhost:8000"
}

var service_url = SERVICE_ENVIRONMENTS.dev
var jwt_token = ""
var connected = false

enum REQUEST_TYPE {
	LOGIN,
	ENTER_RESULT,
	GET_ENTRIES
}

var request_type_methods = {
	REQUEST_TYPE.LOGIN: "_on_logged_in",
	REQUEST_TYPE.ENTER_RESULT: "_on_result_entered",
	REQUEST_TYPE.GET_ENTRIES: "_on_entries_received"
}

const LOG_NAME = "HBBackend"

func _ready():
	login_http_request.connect("request_completed", self, "_on_request_completed")
	
func _on_request_completed(result, response_code, headers, body, request_type, requester):
	requester.queue_free()
	if response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8()).result
		call(request_type_methods[request_type], json)
	else:
		Log.log(self, "Error doing request " + HBUtils.find_key(REQUEST_TYPE, request_type) + str(response_code) + body.get_string_from_utf8())
func _on_logged_in(json):
	jwt_token = json.token
	connected = true
	Log.log(self, "Succesfully logged in")
	HBBackend.get_song_results(SongLoader.songs["ugc_2067258398"], "extreme")
	
func make_request(url: String, payload: Dictionary, method, type, no_auth=false):
	var requester = HTTPRequest.new()
	requester.connect("request_completed", self, "_on_request_completed", [type, requester])
	add_child(requester)
	var headers = ["Content-Type: application/json"]
	if not no_auth:
		headers = ["Authorization: Token " + jwt_token]
	requester.request(service_url + url,  headers, false, method, JSON.print(payload))
func login_steam(ticket: PoolByteArray):
	var payload = {
		"steam_ticket": ticket.hex_encode()
	}
	make_request("/api/users/steam-login", payload, HTTPClient.METHOD_POST, REQUEST_TYPE.LOGIN, true)

func _on_result_entered(result):
	emit_signal("result_entered")
func upload_result(song: HBSong, game_info: HBGameInfo):
	var request = {"result": {}, "song_ugc_id": "0", "song_ugc_type": "Steam"}
	var game_info_dict = game_info.serialize()
	game_info_dict.game_session_type = "Multiplayer"
	if game_info.game_session_type == game_info.GAME_SESSION_TYPE.OFFLINE:
		game_info_dict.game_session_type = "Offline"
	if song is HBPPDSong:
		request.song_ugc_type = "PPD"
		if song.guid == "":
			Log.log(self, "PPD song didn't have a GUID")
			return
		request.song_ugc_id = song.guid
	else:
		if song.ugc_service_name != "Steam Workshop":
			Log.log(self, "Only UGC songs can have scores uploaded")
			return
			request.song_ugc_id = str(song.ugc_id)
	request.result = game_info_dict
	make_request("/api/leaderboard/enter-result", request, HTTPClient.METHOD_POST, REQUEST_TYPE.ENTER_RESULT)

func _on_entries_received(result):
	print("RECEIVED", result)
	emit_signal("entries_received", result)

func get_song_results(song: HBSong, difficulty: String, include_modifiers = false):
	var type = "steam"
	var song_uid = str(song.ugc_id)
	if song is HBPPDSong:
		type = "ppd"
		song_uid = song.guid
	var params = [type, song_uid, difficulty]
	make_request("/api/leaderboard/entries/%s/%s/%s?from=0&to=10&modifiers=true" % params, {}, HTTPClient.METHOD_GET, REQUEST_TYPE.GET_ENTRIES)
