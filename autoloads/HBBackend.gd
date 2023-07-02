extends Node

signal result_entered(result)
signal entries_received(handle, entries, total_pages)

signal user_data_received
signal diagnostics_response_received(response_data)
signal diagnostics_created_request(request_data)
signal request_failed(handle, code, total_pages)
signal score_enter_failed(handle, reason)
signal connection_status_changed
var enable_diagnostics = false

const SERVICE_ENVIRONMENTS = {
	"production": { "url": "https://ph.eirteam.moe", "validate_domain": true },
	"testing": { "url": "https://testing.projectheartbeat.eirteam.moe:8000", "validate_domain": false },
	"dev": { "url": "https://127.0.0.1:8000", "validate_domain": false }
}

const LEADERBOARD_ENTRIES_PER_PAGE = 25

var service_env = SERVICE_ENVIRONMENTS.production
var service_env_name = ""
var jwt_token = ""
var connected = false
var waiting_for_auth = false
var has_user_data = false
var auth_ticket

var queued_requests = []

var request_handle_i = 0

class ResponseData:
	var code: int
	var body: String
	var request_type: int

class RequestData:
	var url: String
	var method: String
	var headers: String
	var body: String

enum REQUEST_TYPE {
	LOGIN,
	ENTER_RESULT,
	GET_ENTRIES,
	GET_USER_DATA
}

var request_type_methods = {
	REQUEST_TYPE.LOGIN: "_on_logged_in",
	REQUEST_TYPE.ENTER_RESULT: "_on_result_entered",
	REQUEST_TYPE.GET_ENTRIES: "_on_entries_received",
	REQUEST_TYPE.GET_USER_DATA: "_on_user_data_received"
}

const LOG_NAME = "HBBackend"

var user_info := HBWebUserInfo.new()

var timer := Timer.new()

class BackendLeaderboardEntry:
	var user: SteamServiceMember
	var rank: int
	var game_info: HBGameInfo
	
	func _init(_user: SteamServiceMember, _rank: int, _game_info: HBGameInfo):
		user = _user
		rank = _rank
		game_info = _game_info
func _ready():
	add_child(timer)
	
	timer.wait_time = 5
	timer.one_shot = false
	timer.connect("timeout", Callable(self, "_on_retry_timer_timed_out"))
	
	PlatformService.service_provider.connect("ticket_ready", Callable(self, "_on_ticket_ready"))
	PlatformService.service_provider.connect("ticket_failed", Callable(self, "_on_ticket_failed"))
	if "--enable-network-diagnostics" in OS.get_cmdline_args():
		enable_diagnostics = true
	var cmdline_args = OS.get_cmdline_args()
	
	if ProjectSettings.get("application/config/service_environment"):
		service_env_name = ProjectSettings.get("application/config/service_environment")
		service_env = SERVICE_ENVIRONMENTS[service_env_name]
	
	for i in range(cmdline_args.size()):
		var arg = cmdline_args[i]
		if arg == "--service-environment":
			if cmdline_args.size() > i+1:
				var env = cmdline_args[i+1]
				if env in SERVICE_ENVIRONMENTS:
					service_env_name = env
					service_env = SERVICE_ENVIRONMENTS[service_env_name]
					break
	
	renew_auth()
	
func _on_retry_timer_timed_out():
	timer.stop()
	if not connected and not waiting_for_auth:
		renew_auth()
	
func _on_user_data_received(json, _params):
	json["type"] = "WebUserInfo"
	var user_info_out = HBWebUserInfo.deserialize(json)
	
	if user_info_out:
		has_user_data = true
		user_info = user_info_out
		emit_signal("user_data_received")
	
func _on_request_completed(result, response_code, headers, body, request_type, requester, params):
	requester.queue_free()
	if enable_diagnostics:
		var data = ResponseData.new()
		data.code = response_code
		data.body = body.get_string_from_utf8()
		data.request_type = request_type
		emit_signal("diagnostics_response_received", data)
	if response_code == 200 and result == OK:
		var test_json_conv = JSON.new()
		test_json_conv.parse(body.get_string_from_utf8())
		var json = test_json_conv.data
		call(request_type_methods[request_type], json, params)
	else:
		emit_signal("request_failed", params.handle, response_code)
		
		if request_type == REQUEST_TYPE.LOGIN:
			timer.start()
			print("TIMER ON!!!")
		if request_type == REQUEST_TYPE.ENTER_RESULT:
			var failure_reason = "Unknown error (%d)" % [response_code]
			var test_json_conv = JSON.new()
			test_json_conv.parse(body.get_string_from_utf8())
			var json = test_json_conv.data
			if json.error == OK:
				if "error_message" in json.result:
					failure_reason = json.result.error_message
			emit_signal("score_enter_failed", failure_reason)
		Log.log(self, "Error doing request " + HBUtils.find_key(REQUEST_TYPE, request_type) + str(response_code) + body.get_string_from_utf8())
func _on_logged_in(json, _params):
	jwt_token = json.token
	connected = true
	emit_signal("connection_status_changed")
	waiting_for_auth = false
	Log.log(self, "Succesfully logged in")
	for request in queued_requests:
		make_request(request.url, request.payload, request.method, request.type, request.params, request.no_auth)
	queued_requests = []
	refresh_user_info()
	
	#HBBackend.get_song_results(SongLoader.songs["ugc_2185496110"], "extreme")
	
func get_jwt_data():
	var test_json_conv = JSON.new()
	test_json_conv.parse(Marshalls.base64_to_utf8(jwt_token.split(".")[1]) + "}")
	return test_json_conv.data
	
func make_request(url: String, payload: Dictionary, method, type, params = {}, no_auth = false, ignore_jwt_expiration = false):
	
	request_handle_i += 1
	
	params = HBUtils.merge_dict({
		"handle": request_handle_i
	},
	params)
	
	if not ignore_jwt_expiration:
		if not jwt_token or (get_jwt_data()["exp"] - Time.get_unix_time_from_system() < 60):
			if not waiting_for_auth:
				renew_auth()
			queued_requests.append({
				"url": url,
				"payload": payload,
				"method": method,
				"type": type,
				"no_auth": no_auth,
				"params": params
			})
			return request_handle_i
	
	var requester = HTTPRequest.new()
	requester.use_threads = true
	requester.connect("request_completed", Callable(self, "_on_request_completed").bind(type, requester, params))
	add_child(requester)
	var headers = ["Content-Type: application/json"]
	if not no_auth:
		headers += ["Authorization: Bearer " + jwt_token]
	requester.request(service_env.url + url,  headers, method, JSON.stringify(payload))
	
	if enable_diagnostics:
		var request_data = RequestData.new()
		request_data.url = url
		request_data.body = JSON.stringify(payload, "  ")
		request_data.method = {
			HTTPClient.METHOD_POST: "POST",
			HTTPClient.METHOD_GET: "GET"
		}[method]
		request_data.headers = str(headers)
		emit_signal("diagnostics_created_request", request_data)
	return request_handle_i
func login_steam():
	var payload = {
		"steam_ticket": auth_ticket.hex_encode()
	}
	return make_request("/auth/steam-login", payload, HTTPClient.METHOD_POST, REQUEST_TYPE.LOGIN, {}, true, true)

func _on_result_entered(result, _params):
	emit_signal("result_entered", result)

func can_have_scores_uploaded(song: HBSong) -> bool:
	if song is HBPPDSong:
		if not song.guid:
			return false
	else:
		if song.ugc_service_name != "Steam Workshop" or (not song.comes_from_ugc() and not song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.BUILT_IN):
			Log.log(self, "Only UGC songs can have scores uploaded")
			return false
	return true

func upload_result(song: HBSong, game_info: HBGameInfo):
	var request = {"game_info": {}, "song_ugc_id": "0", "song_ugc_type": "Steam"}
	var game_info_dict = game_info.serialize(true)
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
	var chart_hash = song.generate_chart_hash(game_info.difficulty)
	if not chart_hash.is_empty():
		request["chart_hash"] = chart_hash
	else:
		Log.log(self, "Empty chart hash for song " + song.title, Log.LogLevel.WARN)

	# HACKISH format conversion and data insertion

	game_info_dict.result.note_ratings = {}
	game_info_dict.result.wrong_note_ratings = {}
	
	request["song_data"] = song.serialize()
	
	for key in game_info.result.note_ratings:
		var key_str = HBUtils.find_key(HBJudge.JUDGE_RATINGS, key) as String
		game_info_dict.result.note_ratings[key_str.capitalize()] = game_info.result.note_ratings[key]
		
	for key in game_info.result.wrong_note_ratings:
		var key_str = HBUtils.find_key(HBJudge.JUDGE_RATINGS, key) as String
		game_info_dict.result.wrong_note_ratings[key_str.capitalize()] = game_info.result.wrong_note_ratings[key]
		
	request.game_info = game_info_dict
	return make_request("/api/leaderboard/enter-result", request, HTTPClient.METHOD_POST, REQUEST_TYPE.ENTER_RESULT, { "song": song })

func _convert_note_ratings(data_dict: Dictionary):
	var out_dict = {}
	for rating_name in data_dict:
		for key in HBJudge.JUDGE_RATINGS:
			if key.to_lower() == rating_name.to_lower():
				out_dict[str(HBJudge.JUDGE_RATINGS[key])] = data_dict[rating_name]
	return out_dict
func _on_entries_received(result, params):
	var entries = []
	for item in result.leaderboard_entries:
		var entry_data = item.entry.entry_data
		var rank = item.rank
		entry_data.result.note_ratings = _convert_note_ratings(entry_data.result.note_ratings)
		entry_data.result.wrong_note_ratings = _convert_note_ratings(entry_data.result.wrong_note_ratings)
		var game_info = HBGameInfo.deserialize(entry_data)
		
		for user in result.users:
			if user.id == item.entry.user_id:
				var member = SteamServiceMember.new(int(user.steam_id))
				entries.append(BackendLeaderboardEntry.new(member, rank, game_info))
				break
	
	emit_signal("entries_received", params.handle, entries, result.total_pages)

func get_song_entries(song: HBSong, difficulty: String, include_modifiers = false, page = 1):
	var type = "steam"
	var song_uid = str(song.ugc_id)
	if song is HBPPDSong:
		type = "ppd"
		song_uid = song.guid
	var params = [type, song_uid, difficulty.uri_encode(), str(page), str(include_modifiers).to_lower()]
	return make_request("/api/leaderboard/get-results/%s/%s/%s?page=%s&modifiers=%s" % params, {}, HTTPClient.METHOD_GET, REQUEST_TYPE.GET_ENTRIES, {"page": page})

func renew_auth():
	if PlatformService.service_provider.implements_leaderboard_auth:
		waiting_for_auth = true
		timer.stop()
		auth_ticket = PlatformService.service_provider.get_leaderboard_auth_token()
func _on_ticket_ready():
	if waiting_for_auth:
		Log.log(self, "Got ticket, attempting login...")
		login_steam()
		waiting_for_auth = false

func _on_ticket_failed(err):
	waiting_for_auth = false
	connected = false
	emit_signal("connection_status_changed")
	Log.log(self, "TICKET RECEPTION FAILED, error code: %d" % [err], Log.LogLevel.ERROR)

func refresh_user_info():
	return make_request("/api/user/get-current-user-data", {}, HTTPClient.METHOD_GET, REQUEST_TYPE.GET_USER_DATA)
