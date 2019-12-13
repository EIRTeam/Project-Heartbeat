extends Node

var scores = {} # contains key with song name into a dictionary that uses difficulty as key

const SCORE_HISTORY_PATH = "user://history.json"
const LOG_NAME = "ScoreHistory"

func _ready():
	load_history()
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
	for song_name in data:
		scores[song_name] = {}
		for difficulty in data[song_name]:
			scores[song_name][difficulty] = HBResult.deserialize(data[song_name][difficulty])
	
func history_to_dict() -> Dictionary:
	var result_dict = {}
	for song_name in scores:
		result_dict[song_name] = {}
		for difficulty in scores[song_name]:
			var result := scores[song_name][difficulty] as HBResult
			result_dict[song_name][difficulty] = result.serialize()
	return result_dict

func save_history():
	var file := File.new()
	if file.open(SCORE_HISTORY_PATH, File.WRITE) == OK:
		file.store_string(JSON.print(history_to_dict(), "  "))
		
func add_result_to_history(result: HBResult):
	if not scores.has(result.song_id):
		scores[result.song_id] = {}
	if scores[result.song_id].has(result.difficulty):
		var current_result = scores[result.song_id][result.difficulty] as HBResult
		if current_result.score > result.score:
			Log.log(self, "Attempted to add a smaller score than what the current one is", Log.LogLeveL.ERROR)
			return
	scores[result.song_id][result.difficulty] = result
	save_history()

func has_result(song_id: String, difficulty: String):
	var r = false
	if scores.has(song_id):
		if scores[song_id].has(difficulty):
			r = true
			
	return r
		
func get_result(song_id: String, difficulty: String):
	var r = null
	if scores.has(song_id):
		if scores[song_id].has(difficulty):
			r = scores[song_id][difficulty]
	return r
