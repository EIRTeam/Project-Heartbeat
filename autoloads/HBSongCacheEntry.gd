extends HBSerializable

class_name HBSongCacheEntry

# example:
# {
#  	"modified": 123123123,
# 	"note_usage": [0, 1]
# }

var song_id

var note_usage_mutex = Mutex.new()
var note_usage_cache = {"modified": -1, "note_usages": {}}

func _init():
	serializable_fields += ["note_usage_cache"]

func get_song():
	if song_id in SongLoader.songs:
		return SongLoader.songs[song_id]

func get_serialized_type():
	return "SongCacheEntry"

func is_note_usage_cached(difficulty: String) -> bool:
	var song = get_song()
	return difficulty in song.charts and \
		difficulty in note_usage_cache.note_usages
		
func update_note_usage(difficulty: String, note_usage: Array):
	var song = get_song()
	note_usage_mutex.lock()
	note_usage_cache.note_usages[difficulty] = note_usage
	var path = song.get_chart_path(difficulty)
	var modified = FileAccess.get_modified_time(path)
	if modified > note_usage_cache.modified:
		note_usage_cache.modified = modified
	note_usage_mutex.unlock()
		
func get_note_usage(difficulty: String) -> Array:
	return note_usage_cache.note_usages[difficulty]
