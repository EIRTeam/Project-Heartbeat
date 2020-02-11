extends HBLeaderboardService

class_name SteamLeaderboardService

func find_leadeboard(leaderboard_name: String):
	print("finding leaderboard ", leaderboard_name)
	
	Steam.findLeaderboard(leaderboard_name)

func _on_leaderboard_found(handle, found):
	print("Found leaderboard ", handle)
	emit_signal("leaderboard_found", handle, found)

func get_leaderboard_entries_for_leaderboard(song_id: String, start, end, type):
	connect("leaderboard_found", self, "_get_leaderboard_entries", [start, end, type], CONNECT_ONESHOT)
	find_leadeboard(song_id)
	
func _get_leaderboard_entries(leaderboard_handle: int, found: int, start: int, end: int, type: int):
	download_leaderboard_entries(leaderboard_handle, start, end, type)

func download_leaderboard_entries(handle: int, start, end, type):
	Steam.connect("leaderboard_scores_downloaded", self, "_on_leaderboard_entries_downloaded", [handle])
	Steam.downloadLeaderboardEntries(start, end, type)
	
func _on_leaderboard_entries_downloaded(handle):
	var entries = Steam.getLeaderboardEntries()
	var leaderboard_entries = []
	for entry in entries:
		var member = SteamServiceMember.new(entry.steamID)
		var leaderboard_entry = HBLeadearboardEntry.new(member)
		leaderboard_entry.rank = entry.global_rank
		leaderboard_entry.score = entry.score
		leaderboard_entries.append(leaderboard_entry)
	emit_signal("leaderboard_entries_downloaded", handle, leaderboard_entries)
