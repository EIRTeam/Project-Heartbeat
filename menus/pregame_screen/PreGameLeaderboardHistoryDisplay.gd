extends MarginContainer

class_name HBPreGameLeaderboardHistoryDisplay

const HISTORY_ENTRY_SCENE = preload("res://menus/pregame_screen/PreGameLeaderboardHistoryEntry.tscn")

@onready var stats_label: Label = get_node("%StatsLabel")
@onready var leaderboard_history_container: VBoxContainer = get_node("%LeaderboardHistoryContainer")
@onready var loading_label: Label = get_node("%LoadingLabel")

var history_update_queued := false

func _queue_history_update():
	if not history_update_queued:
		history_update_queued = true
		_update_history.call_deferred()

var song: HBSong:
	set(val):
		song = val
		_queue_history_update()
var difficulty: String:
	set(val):
		difficulty = val
		_queue_history_update()

func _update_history():
	history_update_queued = false
	
	for child in leaderboard_history_container.get_children():
		child.queue_free()
	focus_mode = FOCUS_NONE
	
	_update_song_stats_label()
	if song and not difficulty.is_empty() and HBBackend.can_have_scores_uploaded(song):
		loading_label.show()
		HBBackend.get_song_history(song, difficulty)
	else:
		loading_label.hide()
func _update_song_stats_label():
	if not song:
		return
	var stats = HBGame.song_stats.get_song_stats(song.id)
	var text = tr("Times Played: %d") % [stats.times_played]
	stats_label.text = text

func _ready() -> void:
	focus_entered.connect(self._focus_entered)
	focus_mode = FOCUS_NONE

func _focus_entered():
	if leaderboard_history_container.get_child_count() > 0:
		(leaderboard_history_container.get_child(0) as Control).grab_focus()

func _on_song_history_received(entry_container: HBBackend.BackendLeaderboardHistoryEntries):
	var entries := entry_container.entries
	if not song:
		loading_label.hide()
	if entry_container.song_ugc_id != str(song.ugc_id) or entry_container.difficulty != difficulty:
		return
	if entries.size() == 0:
		loading_label.hide()
		return


	loading_label.hide()

	var prev_entry: HBBackend.BackendLeaderboardHistoryEntry
	var prev_entry_scene: HBPregameLeaderboardHistoryEntry
	for entry in entries:
		focus_mode = FOCUS_ALL
		var scene := HISTORY_ENTRY_SCENE.instantiate() as HBPregameLeaderboardHistoryEntry
		scene.game_info = entry.game_info
		scene.score_id = entry.id
		if prev_entry:
			scene.diff = prev_entry.game_info.result.score - entry.game_info.result.score
		leaderboard_history_container.add_child(scene)
		scene.set_left(get_node(focus_neighbor_left).get_path())
		if prev_entry_scene:
			prev_entry_scene.set_next(scene.get_path())
			scene.set_prev(prev_entry_scene.get_path())
		prev_entry = entry
		prev_entry_scene = scene
	if entries.size() > 1:
		var etr := leaderboard_history_container.get_child(0) as HBPregameLeaderboardHistoryEntry
		etr.set_prev(prev_entry_scene.get_path())
		prev_entry_scene.set_next(etr.get_path())
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			HBBackend.song_history_received.connect(self._on_song_history_received)
		NOTIFICATION_EXIT_TREE:
			HBBackend.song_history_received.disconnect(self._on_song_history_received)
