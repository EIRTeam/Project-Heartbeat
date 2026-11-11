class_name HBSongStatsLoader

const SONG_STATS_PATH = "user://song_stats.hbdict"

const LOG_NAME = "SongStats"

var song_stats = {}

func get_song_stats_path():
	return HBGame.platform_settings.user_dir_redirect(SONG_STATS_PATH)

func _init_song_stats():
	load_user_stats()

func load_user_stats():
	var ss_path = HBGame.platform_settings.user_dir_redirect(get_song_stats_path())
	if FileAccess.file_exists(ss_path):
		var file = FileAccess.open(ss_path, FileAccess.READ)
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
	var ss_path = HBGame.platform_settings.user_dir_redirect(get_song_stats_path())
	var serialized_song_stats = {}
	for song_id in song_stats:
		var stats = song_stats[song_id] as HBSongStats
		var serialized_stats = stats.serialize()
		serialized_song_stats[song_id] = serialized_stats
	var error := HBUtils.write_var_atomic(ss_path, serialized_song_stats)
	if error != OK:
		Log.log(self, "Error saving song stats: %s" % error, Log.LogLevel.ERROR)

func song_played(song_id: String):
	if not song_id in song_stats:
		song_stats[song_id] = HBSongStats.new()
	song_stats[song_id].times_played += 1

func get_song_stats(song_id: String) -> HBSongStats:
	if song_id in song_stats:
		return song_stats[song_id] as HBSongStats
	else:
		song_stats[song_id] = HBSongStats.new()
		return song_stats[song_id] as HBSongStats
