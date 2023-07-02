extends Control

@export var minimum_position := 0
@export var max_position := 30
@export var show_user_position := true
const LeaderboardItem = preload("res://menus/leaderboard_control/LeaderboardItem.tscn")
@onready var not_found_label = get_node("CenterContainer/Label")
@onready var entries_container = get_node("Entries")
@onready var loading_texture_rect = get_node("CenterContainer2/TextureRect")
var current_leaderboard = ""
signal entries_set
func _ready():
	$CenterContainer2/AnimationPlayer.play("spin")
func _set_leaderboard(value):
	var leaderboard_id = value
	for child in entries_container.get_children():
		if child is HBLeaderboardItem:
			child.queue_free()
	if leaderboard_id and PlatformService.service_provider.implements_leaderboards:
		not_found_label.hide()
		var provider = PlatformService.service_provider.leaderboard_provider as HBLeaderboardService
		provider.connect("leaderboard_found", Callable(self, "_leaderboard_found").bind(), CONNECT_ONE_SHOT)
		provider.find_leadeboard(value)
		not_found_label.hide()
		loading_texture_rect.show()
	else:
		not_found_label.show()
		loading_texture_rect.hide()

func set_entries(entries: Array):
	_on_leaderboard_entries_downloaded(0, entries)
	emit_signal("entries_set")

func set_song(song_id, difficulty):
	current_leaderboard = song_id + "_%s" % difficulty
	_set_leaderboard(current_leaderboard)

func _leaderboard_found(name, handle, found):
	if not found:
		not_found_label.show()
		loading_texture_rect.hide()
	else:
		not_found_label.hide()
		var provider = PlatformService.service_provider.leaderboard_provider as HBLeaderboardService
		if not provider.is_connected("leaderboard_entries_downloaded", Callable(self, "_on_leaderboard_entries_downloaded")):
			provider.connect("leaderboard_entries_downloaded", Callable(self, "_on_leaderboard_entries_downloaded"))
		provider.get_leaderboard_entries_for_leaderboard(current_leaderboard, minimum_position, max_position, HBLeaderboardService.LEADERBOARD_DATA_REQUEST_TYPE.GLOBAL)
func _on_leaderboard_entries_downloaded(handle, entries: Array):
	loading_texture_rect.hide()
	not_found_label.hide()
	for i in range(entries.size()):
		var entry = entries[i]
		var item = LeaderboardItem.instantiate()
		item.entry = entry
		item.odd = i % 2 == 0
		entries_container.add_child(item)
