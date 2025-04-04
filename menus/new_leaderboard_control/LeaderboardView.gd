extends Control

class_name LeaderboardView

signal entries_received(handle, entries, total_pages)
signal entries_request_failed()
var current_request_handle: HBBackend.BackendRequestToken
@onready var entries_container = self

const LeaderboardItem = preload("res://menus/new_leaderboard_control/LeaderboardItem.tscn")

@export var labels_node_path: NodePath

func get_labels_node():
	return get_node(labels_node_path)
	
func fetch_entries(song: HBSong, difficulty: String, include_modifiers: bool, page = 1):
	for item in entries_container.get_children():
		entries_container.remove_child(item)
		item.queue_free()
	var labels_node = get_labels_node()
	labels_node.not_found_label.hide()
	labels_node.not_available_label.hide()
	labels_node.spinner.hide()
	labels_node.error_label.hide()
	if HBBackend.can_have_scores_uploaded(song):
		labels_node.spinner.show()
		labels_node.spinner_animation_player.play("spin")
		if current_request_handle:
			current_request_handle.entries_received.disconnect(_on_entries_received)
			current_request_handle.request_failed.disconnect(_on_request_failed)
		current_request_handle = HBBackend.get_song_entries(song, difficulty, include_modifiers, page)
		print("CALL")
		current_request_handle.entries_received.connect(_on_entries_received)
		current_request_handle.request_failed.connect(_on_request_failed)
	else:
		labels_node.not_available_label.show()
func _on_entries_received(entries: Array[HBBackend.BackendLeaderboardEntry], total_pages):
	var labels_node = get_labels_node()
	labels_node.spinner_animation_player.stop()
	if total_pages == 0:
		labels_node.not_found_label.show()
	labels_node.spinner.hide()
	set_entries(entries)
	emit_signal("entries_received", entries, total_pages)
	
	if get_tree():
		await get_tree().process_frame

func set_entries(entries: Array):
	for item in entries_container.get_children():
		entries_container.remove_child(item)
		item.queue_free()
	for entry in entries:
		var item = LeaderboardItem.instantiate()
		item.entry = entry
		entries_container.add_child(item)

func _on_request_failed(code):
	var labels_node = get_labels_node()
	labels_node.spinner_animation_player.stop()
	labels_node.spinner.hide()
	if code == 404:
		labels_node.not_found_label.show()
	else:
		labels_node.error_label.show()
	emit_signal("entries_request_failed")
