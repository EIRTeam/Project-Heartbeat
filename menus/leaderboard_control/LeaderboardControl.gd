extends VBoxContainer

export(int) var minimum_position := 0
export(int) var max_position := 10
export(bool) var show_user_position := true
var song_id: String setget set_song_id
const LeaderboardItem = preload("res://menus/leaderboard_control/LeaderboardItem.tscn")

func _ready():
	set_song_id("imademo_2012")

func set_song_id(value):
	song_id = value
	for child in get_children():
		child.queue_free()
	if song_id and PlatformService.service_provider.implements_leaderboards:
		var provider = PlatformService.service_provider.leaderboard_provider as HBLeaderboardService
		provider.connect("leaderboard_entries_downloaded", self, "_on_leaderboard_entries_downloaded")
		provider.get_leaderboard_entries_for_song(song_id, minimum_position, max_position, HBLeaderboardService.LEADERBOARD_DATA_REQUEST_TYPE.GLOBAL)

func _on_leaderboard_entries_downloaded(handle, entries: Array):
	print(entries)
	for i in range(entries.size()):
		var entry = entries[i]
		var item = LeaderboardItem.instance()
		item.entry = entry
		item.odd = i % 2 == 0
		add_child(item)
