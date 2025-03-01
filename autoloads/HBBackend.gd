extends Node


signal user_data_received
signal diagnostics_response_received(response_data)
signal diagnostics_created_request(request_data)
signal request_failed(token: BackendRequestToken, code, total_pages)
signal connection_status_changed
signal wrong_timezone_detected
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
var auth_ticket: HBAuthTicketForWebAPI
var _notified_wrong_timezone := false

var queued_requests: Array[BackendRequestToken] = []

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
	GET_USER_DATA,
	GET_USER_SONG_HISTORY
}

var request_type_methods = {
	REQUEST_TYPE.LOGIN: "_on_logged_in",
	REQUEST_TYPE.ENTER_RESULT: "_on_result_entered",
	REQUEST_TYPE.GET_ENTRIES: "_on_entries_received",
	REQUEST_TYPE.GET_USER_DATA: "_on_user_data_received",
	REQUEST_TYPE.GET_USER_SONG_HISTORY: "_on_user_song_history_received"
}

const LOG_NAME = "HBBackend"

var user_info := HBWebUserInfo.new()

var timer := Timer.new()

class BackendRequestToken:
	signal entries_received(entries: Array[BackendLeaderboardEntry], total_pages: int)
	signal request_failed(code: int)
	signal result_entered(result: LeaderboardScoreUploadedResult)
	signal song_history_received(entries: BackendLeaderboardHistoryEntries)
	signal score_enter_failed(handle, reason)
	signal request_cancelled
	
	var url: String
	var payload: Dictionary
	var method: int
	var type: REQUEST_TYPE
	var no_auth: bool
	var params: Dictionary
	var request: HTTPRequest
	
	func cancel_request():
		request_cancelled.emit()

class BackendLeaderboardEntry:
	var user: SteamServiceMember
	var rank: int
	var game_info: HBGameInfo
	
	func _init(_user: SteamServiceMember, _rank: int, _game_info: HBGameInfo):
		user = _user
		rank = _rank
		game_info = _game_info
		
class BackendLeaderboardHistoryEntries:
	var song_ugc_id: String
	var difficulty: String
	var entries: Array[BackendLeaderboardHistoryEntry]
	func _init(_song_ugc_id: String, _difficulty: String, _entries: Array[BackendLeaderboardHistoryEntry]):
		song_ugc_id = _song_ugc_id
		difficulty = _difficulty
		entries = _entries
	
class BackendLeaderboardHistoryEntry:
	var id: int
	var rank: int
	var game_info: HBGameInfo
	func _init(_id: int, _rank: int, _game_info: HBGameInfo):
		game_info = _game_info
		rank = _rank
		id = _id
		
class LeaderboardScoreUploadedResult:
	class ExperienceGainBreakdown:
		var first_time: bool
		var first_time_experience_gain: int
		var rating_experience_gain: int
		func get_total_experience_gain() -> int:
			var val := rating_experience_gain
			if first_time:
				val += first_time_experience_gain
			return val
	var level_change: int
	var experience_change: int
	var beat_previous_record: bool
	var previous_record: HBResult
	var experience_gain_breakdown: ExperienceGainBreakdown
	var score_id: int
		
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
	
func _on_user_data_received(json, token: BackendRequestToken):
	json["type"] = "WebUserInfo"
	var user_info_out = HBWebUserInfo.deserialize(json)
	
	if user_info_out:
		has_user_data = true
		user_info = user_info_out
		user_data_received.emit()
	
func _on_request_completed(result, response_code, headers, body, request_type, requester, token: BackendRequestToken):
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
		call(request_type_methods[request_type], json, token)
	else:
		emit_signal("request_failed", token, response_code)
		token.request_failed.emit(response_code)
		
		if request_type == REQUEST_TYPE.LOGIN:
			timer.start()
		if request_type == REQUEST_TYPE.ENTER_RESULT:
			var failure_reason = "Unknown error (%d)" % [response_code]
			var test_json_conv = JSON.new()
			var err := test_json_conv.parse(body.get_string_from_utf8())
			var json = test_json_conv.data
			if err == OK:
				if "error_message" in json:
					failure_reason = json.error_message
			else:
				failure_reason = "Request error code %d %s" % [result, str(body) if body else ""]
			token.score_enter_failed.emit(failure_reason)
		Log.log(self, "Error doing request " + HBUtils.find_key(REQUEST_TYPE, request_type) + " " + str(response_code) + body.get_string_from_utf8())
func _on_logged_in(json, _params):
	jwt_token = json.token
	# Check if the token is immediately invalid, if so, we might have the wrong system timezone
	if not _notified_wrong_timezone and (get_jwt_data()["exp"] - Time.get_unix_time_from_system() < 60):
		wrong_timezone_detected.emit()
		_notified_wrong_timezone = true
		return
	else:
		_notified_wrong_timezone = false
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

func _on_request_cancelled(request_token: BackendRequestToken):
	if request_token.request:
		request_token.request.cancel_request()
	else:
		queued_requests.erase(request_token)

func make_request(url: String, payload: Dictionary, method: int, type: REQUEST_TYPE, params = {}, no_auth = false, ignore_jwt_expiration = false):
	if not ignore_jwt_expiration and _notified_wrong_timezone:
		return
	
	request_handle_i += 1
	var request_token := BackendRequestToken.new()
	request_token.request_cancelled.connect(_on_request_cancelled.bind(request_token))
	request_token.url = url
	request_token.payload = payload
	request_token.method = method
	request_token.type = type
	request_token.no_auth = no_auth
	request_token.params = params
	
	params = HBUtils.merge_dict({
		"handle": request_handle_i
	},
	params)
	
	if not ignore_jwt_expiration:
		if not jwt_token or (get_jwt_data()["exp"] - Time.get_unix_time_from_system() < 60):
			if not waiting_for_auth:
				renew_auth()

			queued_requests.append(request_token)
			return request_token
	
	var requester = HTTPRequest.new()
	request_token.request = requester
	requester.use_threads = true
	if not service_env.validate_domain:
		var tls_options := TLSOptions.client_unsafe()
		requester.set_tls_options(tls_options)
	requester.connect("request_completed", Callable(self, "_on_request_completed").bind(type, requester, request_token))
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
	return request_token
func login_steam() -> BackendRequestToken:
	var payload = {
		"steam_ticket": auth_ticket.ticket_data.hex_encode()
	}
	return make_request("/auth/steam-login", payload, HTTPClient.METHOD_POST, REQUEST_TYPE.LOGIN, {}, true, true)

func _on_result_entered(result, token: BackendRequestToken):
	var entry_result := LeaderboardScoreUploadedResult.new()
	entry_result.beat_previous_record = result.get("beat_previous_record", false)
	entry_result.experience_change = result.get("experience_change", 0)
	entry_result.level_change = result.get("level_change", 0)
	entry_result.experience_gain_breakdown = LeaderboardScoreUploadedResult.ExperienceGainBreakdown.new()
	entry_result.score_id = result.get("score_id", -1)
	assert("experience_gain_breakdown" in result)
	if "experience_gain_breakdown" in result:
		entry_result.experience_gain_breakdown.first_time = result.experience_gain_breakdown.get("first_time", false)
		entry_result.experience_gain_breakdown.first_time_experience_gain = result.experience_gain_breakdown.get("first_time_experience_gain", 0)
		entry_result.experience_gain_breakdown.rating_experience_gain = result.experience_gain_breakdown.get("rating_experience_gain", 0)
		
	if "previous_record" in result:
		if "entry_data" in result.previous_record:
			if "result" in result.previous_record.entry_data:
				entry_result.previous_record = HBSerializable.deserialize(result.previous_record.entry_data.result)
	token.result_entered.emit(entry_result)

func can_have_scores_uploaded(song: HBSong) -> bool:
	if song is HBPPDSong:
		if not song.guid:
			return false
	else:
		if song.ugc_service_name != "Steam Workshop" or (not song.comes_from_ugc() and not song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.BUILT_IN):
			Log.log(self, "Only UGC songs can have scores uploaded")
			return false
	return true

func upload_result(song: HBSong, game_info: HBGameInfo) -> BackendRequestToken:
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

func _convert_web_note_ratings(dict: Dictionary) -> Dictionary:
	var out_dict := {}
	const RATING_MAP := {
		"Cool": HBJudge.JUDGE_RATINGS.COOL,
		"Fine": HBJudge.JUDGE_RATINGS.FINE,
		"Sad": HBJudge.JUDGE_RATINGS.SAD,
		"Safe": HBJudge.JUDGE_RATINGS.SAFE,
		"Worst": HBJudge.JUDGE_RATINGS.WORST
	}
	for rating in RATING_MAP:
		if rating in dict:
			out_dict[RATING_MAP[rating]] = dict[rating]
			
	return out_dict
	
func _on_user_song_history_received(result: Dictionary, token: BackendRequestToken):
	var entries: Array[BackendLeaderboardHistoryEntry]
	for entry in result.get("leaderboard_entries", []):
		entry = entry.get("entry", {})
		var entry_data := entry.get("entry_data") as Dictionary
		var entry_result := entry_data.get("result", {}) as Dictionary

		entry_result["note_ratings"] = _convert_web_note_ratings(entry_result.get("note_ratings", {}) as Dictionary)
		entry_result["wrong_note_ratings"] = _convert_web_note_ratings(entry_result.get("wrong_note_ratings", {}) as Dictionary)
		if not entry_result.get("note_ratings", {}).size() == HBJudge.JUDGE_RATINGS.size():
			printerr("Skipping song with wrong note rating count, bug??", entry_result)
			continue
		var game_info := HBSerializable.deserialize(entry_data) as HBGameInfo
		if not game_info:
			continue
		entries.push_back(BackendLeaderboardHistoryEntry.new(entry.get("id", 0), entry.get("rank", 0), game_info))
	var entries_container := BackendLeaderboardHistoryEntries.new(result.get("song_ugc_id", ""), result.get("difficulty", ""), entries)
	token.song_history_received.emit(entries_container)
	
	
func _on_entries_received(result: Dictionary, token: BackendRequestToken):
	var entries: Array[BackendLeaderboardEntry]
	for item in result.leaderboard_entries:
		var entry_data = item.entry.entry_data
		var rank = item.rank
		entry_data.result.note_ratings = _convert_web_note_ratings(entry_data.result.note_ratings)
		entry_data.result.wrong_note_ratings = _convert_web_note_ratings(entry_data.result.wrong_note_ratings)
		var game_info = HBGameInfo.deserialize(entry_data)
		
		for user in result.users:
			if user.id == item.entry.user_id:
				var member = SteamServiceMember.new(int(user.steam_id))
				entries.append(BackendLeaderboardEntry.new(member, rank, game_info))
				break
	token.entries_received.emit(entries, result.total_pages)

func get_song_entries(song: HBSong, difficulty: String, include_modifiers = false, page = 1) -> BackendRequestToken:
	var type = "steam"
	var song_uid = str(song.ugc_id)
	if song is HBPPDSong:
		type = "ppd"
		song_uid = song.guid
	var params = [type, song_uid, difficulty.uri_encode(), str(page), str(include_modifiers).to_lower()]
	return make_request("/api/leaderboard/get-results/%s/%s/%s?page=%s&modifiers=%s" % params, {}, HTTPClient.METHOD_GET, REQUEST_TYPE.GET_ENTRIES, {"page": page})

func get_song_history(song: HBSong, difficulty: String) -> BackendRequestToken:
	var type = "steam"
	var song_uid = str(song.ugc_id)
	if song is HBPPDSong:
		type = "ppd"
		song_uid = song.guid
	var params = [type, song_uid, difficulty.uri_encode()]
	return make_request("/api/user/get-song-history/%s/%s/%s" % params, {}, HTTPClient.METHOD_GET, REQUEST_TYPE.GET_USER_SONG_HISTORY)

func renew_auth():
	if PlatformService.service_provider.implements_leaderboard_auth:
		waiting_for_auth = true
		timer.stop()
		auth_ticket = PlatformService.service_provider.request_new_auth_token()
		if auth_ticket:
			auth_ticket.ticket_received.connect(self._on_ticket_ready)

func _on_ticket_ready(success: bool):
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
