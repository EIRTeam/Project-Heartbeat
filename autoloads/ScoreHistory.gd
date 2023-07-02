extends Node

var scores = {} # contains key with song name into a dictionary that uses difficulty as key

const SCORE_HISTORY_PATH = "user://history.json"
const LOG_NAME = "ScoreHistory"

signal score_entered(song, difficulty)
signal score_uploaded(score_result)
signal score_upload_failed(reason)
var games_queued_for_upload = []

var last_song_uploaded

func _ready():
	load_history()
	HBBackend.connect("result_entered", Callable(self, "_on_leaderboard_score_uploaded"))
	HBBackend.connect("score_enter_failed", Callable(self, "_on_score_enter_failed"))
	if PlatformService.service_provider.implements_leaderboards:
		var lb_provider = PlatformService.service_provider.leaderboard_provider
		lb_provider.connect("score_uploaded", Callable(self, "_on_leaderboard_score_uploaded"))
	
func _on_score_enter_failed(reason):
	emit_signal("score_upload_failed", reason)
		
func _on_leaderboard_score_uploaded(result):
	emit_signal("score_entered", last_song_uploaded.song_id, last_song_uploaded.difficulty)
	emit_signal("score_uploaded", result)

func load_history():
	if FileAccess.file_exists(SCORE_HISTORY_PATH):
		var file := FileAccess.open(SCORE_HISTORY_PATH, FileAccess.READ)
		if FileAccess.get_open_error() == OK:
			var test_json_conv = JSON.new()
			var err := test_json_conv.parse(file.get_as_text())
			var result = test_json_conv.get_data()
			if err == OK:
				history_from_dict(result)
				Log.log(self, "Successfully loaded score history from " + SCORE_HISTORY_PATH)
			else:
				Log.log(self, "Error loading score history, error code: " + str(test_json_conv.get_error_message()), Log.LogLevel.ERROR)

func history_from_dict(data: Dictionary):
	var found_error = false
	var found_legacy_result = false
	for song_name in data:
		scores[song_name] = {}
		for difficulty in data[song_name]:
			var result = HBHistoryEntry.deserialize(data[song_name][difficulty]) as HBHistoryEntry
			# Fixes invalid entries from 0.11.0...
			if result.highest_score_info.song_id != song_name:
				result.highest_score_info.song_id = song_name
				result.highest_score_info.result.score = result.highest_score
			elif result.highest_score < result.highest_score_info.result.score:
				result.highest_score = result.highest_score_info.result.score
			
			if result is HBGameInfo:
				var r = HBHistoryEntry.new()
				r.update(result)
				scores[song_name][difficulty] = r
				found_legacy_result = true
			elif not result is HBHistoryEntry:
				found_error = true
			else:
				scores[song_name][difficulty] = result
	if found_error or found_legacy_result:
		save_history()
func history_to_dict() -> Dictionary:
	var result_dict = {}
	for song_name in scores:
		result_dict[song_name] = {}
		for difficulty in scores[song_name]:
			var result := scores[song_name][difficulty] as HBHistoryEntry
			result_dict[song_name][difficulty] = result.serialize()
	return result_dict

func save_history():
	var file := FileAccess.open(SCORE_HISTORY_PATH, FileAccess.WRITE)
	if FileAccess.get_open_error() == OK:
		var contents = JSON.stringify(history_to_dict(), "  ")
		file.store_string(contents)
		PlatformService.service_provider.write_remote_file_async(SCORE_HISTORY_PATH.get_file(), contents.to_utf8_buffer())
		
func add_result_to_history(game_info: HBGameInfo):
	var result = game_info.result as HBResult
	if result.used_cheats or not game_info.is_leaderboard_legal():
		Log.log(self, "Can't enter a cheated result")
		if PlatformService.service_provider.implements_leaderboards:
			emit_signal("score_entered", game_info.song_id, game_info.difficulty)
	else:
		if not scores.has(game_info.song_id):
			scores[game_info.song_id] = {}
			emit_signal("score_entered", game_info.song_id, game_info.difficulty)
		var found_previous_entry: HBHistoryEntry = null
		if scores[game_info.song_id].has(game_info.difficulty):
			found_previous_entry = scores[game_info.song_id][game_info.difficulty]
			found_previous_entry.update(game_info)
			if (scores[game_info.song_id][game_info.difficulty] as HBHistoryEntry).is_result_better(result):
				Log.log(self, "Attempted to add a smaller score than what the current one is", Log.LogLevel.ERROR)
		if not found_previous_entry:
			found_previous_entry = HBHistoryEntry.new()
			found_previous_entry.update(game_info)
			scores[game_info.song_id][game_info.difficulty] = found_previous_entry
		var song = SongLoader.songs[game_info.song_id] as HBSong
		if HBBackend.can_have_scores_uploaded(song):
			last_song_uploaded = game_info
			HBBackend.upload_result(song, game_info)
		else:
			emit_signal("score_entered", game_info.song_id, game_info.difficulty)

		save_history()

func has_result(song_id: String, difficulty: String):
	var r = false
	if scores.has(song_id):
		if scores[song_id].has(difficulty):
			r = true
			
	return r
		
func get_data(song_id: String, difficulty: String) -> HBHistoryEntry:
	var r = null
	if scores.has(song_id):
		if scores[song_id].has(difficulty):
			r = scores[song_id][difficulty]
	return r
