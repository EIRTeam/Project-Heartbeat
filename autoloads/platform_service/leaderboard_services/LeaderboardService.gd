class_name HBLeaderboardService

signal leaderboard_entries_downloaded(leaderboard_handle, entries)
signal leaderboard_found(handle, found)
enum LEADERBOARD_DATA_REQUEST_TYPE {
	GLOBAL = 0,
	AROUND_USER = 1,
	FRIENDS = 2
}

func _init():
	Steam.connect("leaderboard_find_result", self, "_on_leaderboard_found", [])

func find_leadeboard(leaderboard_name: String):
	pass

func get_leaderboard_entries_for_song(song_id: String, start, end, type):
	pass

func download_leaderboard_entries(handle: int, start, end, type):
	pass
	
func get_leaderboard_entry():
	pass
