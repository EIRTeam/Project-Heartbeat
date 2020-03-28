extends Node

var scores = {} # contains key with song name into a dictionary that uses difficulty as key

const SCORE_HISTORY_PATH = "user://history.json"
const LOG_NAME = "ScoreHistory"

signal score_entered(song, difficulty)

var games_queued_for_upload = []

func _ready():
	load_history()
	if PlatformService.service_provider.implements_leaderboards:
		var lb_provider = PlatformService.service_provider.leaderboard_provider
		lb_provider.connect("score_uploaded", self, "_on_leaderboard_score_uploaded")
	
		
func _on_leaderboard_score_uploaded(success, lb_name, score, score_changed, new_rank, old_rank):
	for game_info in games_queued_for_upload:
		var song = SongLoader.songs[game_info.song_id] as HBSong
		if song.get_leaderboard_name(game_info.difficulty) == lb_name:
			emit_signal("score_entered", game_info.song_id, game_info.difficulty)
		games_queued_for_upload.erase(game_info)
		break
		
func load_history():
	var file := File.new()
	if file.file_exists(SCORE_HISTORY_PATH):
		if file.open(SCORE_HISTORY_PATH, File.READ) == OK:
			var result = JSON.parse(file.get_as_text())
			if result.error == OK:
				history_from_dict(result.result)
				Log.log(self, "Successfully loaded score history from " + SCORE_HISTORY_PATH)
			else:
				Log.log(self, "Error loading score history, error code: " + str(result.error), Log.LogLevel.ERROR)

func history_from_dict(data: Dictionary):
	var found_error = false
	for song_name in data:
		scores[song_name] = {}
		for difficulty in data[song_name]:
			var result = HBGameInfo.deserialize(data[song_name][difficulty])
			if not result is HBGameInfo:
				found_error = true
			else:
				scores[song_name][difficulty] = result
	if found_error:
		save_history()
func history_to_dict() -> Dictionary:
	var result_dict = {}
	for song_name in scores:
		result_dict[song_name] = {}
		for difficulty in scores[song_name]:
			var result := scores[song_name][difficulty] as HBGameInfo
			result_dict[song_name][difficulty] = result.serialize()
	return result_dict

func save_history():
	var file := File.new()
	if file.open(SCORE_HISTORY_PATH, File.WRITE) == OK:
		var contents = JSON.print(history_to_dict(), "  ")
		file.store_string(contents)
		PlatformService.service_provider.write_remote_file_async(SCORE_HISTORY_PATH.get_file(), contents.to_utf8())
		
func add_result_to_history(game_info: HBGameInfo):
	var result = game_info.result as HBResult
	if not result.used_cheats:
		Log.log(self, "Can't enter a cheated result")
		if PlatformService.service_provider.implements_leaderboards:
			emit_signal("score_entered", game_info.song_id, game_info.difficulty)
	else:
		if not scores.has(game_info.song_id):
			scores[game_info.song_id] = {}
			emit_signal("score_entered", game_info.song_id, game_info.difficulty)
			
		if scores[game_info.song_id].has(game_info.difficulty):
			var existing_result = scores[game_info.song_id][game_info.difficulty].result as HBResult
			if existing_result.score > result.score:
				Log.log(self, "Attempted to add a smaller score than what the current one is", Log.LogLevel.ERROR)
				return
		scores[game_info.song_id][game_info.difficulty] = game_info

		if PlatformService.service_provider.implements_leaderboards:
			var leaderboard_service = PlatformService.service_provider.leaderboard_provider as HBLeaderboardService
			var song = SongLoader.songs[game_info.song_id] as HBSong
			games_queued_for_upload.append(game_info)
			leaderboard_service.upload_score(song.get_leaderboard_name(game_info.difficulty), result.score, result.get_percentage())
		else:
			emit_signal("score_entered", game_info.song_id, game_info.difficulty)
		save_history()
	


func has_result(song_id: String, difficulty: String):
	var r = false
	if scores.has(song_id):
		if scores[song_id].has(difficulty):
			r = true
			
	return r
		
func get_result(song_id: String, difficulty: String) -> HBResult:
	var r = null
	if scores.has(song_id):
		if scores[song_id].has(difficulty):
			r = scores[song_id][difficulty].result
	return r
