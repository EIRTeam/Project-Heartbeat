extends Node

var scores = {} # contains key with song name into a dictionary that uses difficulty as key

const SCORE_HISTORY_PATH = "user://history.json"
const LOG_NAME = "ScoreHistory"

signal score_entered(song, difficulty)

var sessions_queued_for_upload = []

func _ready():
	load_history()
	if PlatformService.service_provider.implements_leaderboards:
		var lb_provider = PlatformService.service_provider.leaderboard_provider
		lb_provider.connect("score_uploaded", self, "_on_leaderboard_score_uploaded")
	
		
func _on_leaderboard_score_uploaded(success, lb_name, score, score_changed, new_rank, old_rank):
	for session in sessions_queued_for_upload:
		var song = SongLoader.songs[session.song_id] as HBSong
		if song.get_leaderboard_name(session.difficulty) == lb_name:
			emit_signal("score_entered", session.id, session.difficulty)
		sessions_queued_for_upload.erase(session)
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
			var result = HBGameSession.deserialize(data[song_name][difficulty])
			if not result is HBGameSession:
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
			var result := scores[song_name][difficulty] as HBGameSession
			result_dict[song_name][difficulty] = result.serialize()
	return result_dict

func save_history():
	var file := File.new()
	if file.open(SCORE_HISTORY_PATH, File.WRITE) == OK:
		var contents = JSON.print(history_to_dict(), "  ")
		file.store_string(contents)
		PlatformService.service_provider.write_remote_file_async(SCORE_HISTORY_PATH.get_file(), contents.to_utf8())
		
func add_result_to_history(session: HBGameSession):
	var result = session.result as HBResult
	if not scores.has(session.song_id):
		scores[session.song_id] = {}
		
	if PlatformService.service_provider.implements_leaderboards:
		var leaderboard_service = PlatformService.service_provider.leaderboard_provider as HBLeaderboardService
		var song = SongLoader.songs[session.song_id] as HBSong
		sessions_queued_for_upload.append(session)
		leaderboard_service.upload_score(song.get_leaderboard_name(session.difficulty), result.score, result.get_percentage())
	else:
		emit_signal("score_entered", session.song_id, session.difficulty)
		
	if scores[session.song_id].has(session.difficulty):
		var current_result = scores[session.song_id][session.difficulty].result as HBResult
		if current_result.score > result.score:
			Log.log(self, "Attempted to add a smaller score than what the current one is", Log.LogLevel.ERROR)
			return
	scores[session.song_id][session.difficulty] = session
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
