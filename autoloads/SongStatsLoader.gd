const SONG_STATS_PATH = "user://song_stats.hbdict"

class_name HBSongStatsLoader

const LOG_NAME = "SongStats"

var song_stats = {}

func _init_song_stats():
	load_user_stats()

func load_user_stats():
	var file = File.new()
	if file.file_exists(SONG_STATS_PATH):
		file.open(SONG_STATS_PATH, File.READ)
		var new_stats = file.get_var()
		if new_stats is Dictionary:
			for song_id in new_stats:
				var r = HBSerializable.deserialize(new_stats[song_id])
				if r is HBSongStats:
					song_stats[song_id] = r
				else:
					Log.log(self, "Error deserializing song stats for song %s", [song_id])
		else:
			Log.log(self, "Deserialized song stats file did not contain a dictionary", Log.LogLevel.ERROR)
		file.close()
func save_song_stats():
	var file = File.new()
	file.open(SONG_STATS_PATH, File.WRITE)
	var serialized_song_stats = {}
	for song_id in song_stats:
		var stats = song_stats[song_id] as HBSongStats
		var serialized_stats = stats.serialize()
		serialized_song_stats[song_id] = serialized_stats
	file.store_var(serialized_song_stats)
	file.close()

func song_played(song_id: String):
	if not song_id in song_stats:
		song_stats[song_id] = HBSongStats.new()
	song_stats[song_id].times_played += 1

func get_song_stats(song_id: String) -> HBSongStats:
	if song_id in song_stats:
		return song_stats[song_id] as HBSongStats
	else:
		return HBSongStats.new()
