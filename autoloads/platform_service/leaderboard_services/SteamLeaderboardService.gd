extends HBLeaderboardService

class_name SteamLeaderboardService

var queued_leaderboard_uploads = {}
var queued_leaderboard_entry_loads = {}

func _init():
	Steam.connect("leaderboard_find_result", Callable(self, "_on_leaderboard_found_internal").bind())
	Steam.connect("leaderboard_scores_downloaded", Callable(self, "_on_leaderboard_entries_downloaded"))
	Steam.connect("leaderboard_score_uploaded", Callable(self, "_on_leaderboard_uploaded"))
func find_leadeboard(leaderboard_name: String):
	print("finding leaderboard ", leaderboard_name)
	Steam.findLeaderboard(leaderboard_name)

func _on_leaderboard_found_internal(handle, found):
	if found:
		var leaderboard_name = Steam.getLeaderboardName()
		if leaderboard_name in queued_leaderboard_uploads:
			var data = queued_leaderboard_uploads[leaderboard_name]
			_on_upload_score(leaderboard_name, handle, data[0], data[1])
			queued_leaderboard_uploads.erase(leaderboard_name)
		if leaderboard_name in queued_leaderboard_entry_loads:
			var data = queued_leaderboard_entry_loads[leaderboard_name]
			data["handle"] = handle
			download_leaderboard_entries(data.start, data.end, data.type)
			
	emit_signal("leaderboard_found", Steam.getLeaderboardName(), handle, found)

func get_leaderboard_entries_for_leaderboard(song_id: String, start, end, type):
	queued_leaderboard_entry_loads[song_id] = {
		"start": start,
		"end": end,
		"type": type
	}
	find_leadeboard(song_id)

func download_leaderboard_entries(start, end, type):
	Steam.downloadLeaderboardEntries(start, end, type)
	
func _on_leaderboard_entries_downloaded(handle, entries):
	if Steam.getLeaderboardName() in queued_leaderboard_entry_loads:
		var leaderboard_entries = []
		for entry in entries:
			var member = SteamServiceMember.new(entry.steamID)
			var leaderboard_entry = HBLeadearboardEntry.new(member)
			leaderboard_entry.rank = entry.global_rank
			leaderboard_entry.score = entry.score
			leaderboard_entry.percentage = entry.details[0]/10000.0
			leaderboard_entries.append(leaderboard_entry)
		emit_signal("leaderboard_entries_downloaded", handle, leaderboard_entries)

func upload_score(leaderboard_name, score, percentage):
	queued_leaderboard_uploads[leaderboard_name] = [score, int(percentage*10000)]
	find_leadeboard(leaderboard_name)
func _on_upload_score(leaderboard_name, leaderboard_handle, score, percentage):
	Steam.uploadLeaderboardScore(score, LEADERBOARD_UPLOAD_SCORE_METHOD.KEEP_BEST, PackedInt32Array([percentage]))

func _on_leaderboard_uploaded(success, score, score_changed, new_rank, old_rank):
	if success:
		emit_signal("score_uploaded", success, Steam.getLeaderboardName(), score, score_changed, new_rank, old_rank)
	else:
		emit_signal("score_uploaded", success, "", score, score_changed, new_rank, old_rank)
