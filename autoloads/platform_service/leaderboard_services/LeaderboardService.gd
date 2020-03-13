class_name HBLeaderboardService

signal leaderboard_entries_downloaded(leaderboard_handle, entries)
signal leaderboard_found(name, handle, found)
signal score_uploaded(success, lb_name, score, score_changed, new_rank, old_rank)
enum LEADERBOARD_DATA_REQUEST_TYPE {
	GLOBAL = 0,
	AROUND_USER = 1,
	FRIENDS = 2
}

enum LEADERBOARD_UPLOAD_SCORE_METHOD {
	NONE,
	KEEP_BEST,
	FORCE_UPDATE
}

func _init():
	pass

func find_leadeboard(leaderboard_name: String):
	pass

func get_leaderboard_entries_for_leaderboard(leaderboard_id: String, start, end, type):
	pass

func download_leaderboard_entries(start, end, type):
	pass
	
func get_leaderboard_entry():
	pass
func upload_score(leaderboard_name, score, percentage):
	pass
