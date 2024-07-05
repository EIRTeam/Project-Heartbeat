@tool
extends Control

class_name HBReplayContainer

@onready var scroll_list: HBUniversalScrollList = get_node("%ScrollList")
@onready var item_list: VBoxContainer = get_node("%ItemList")

signal replay_selected(replay_package: HBReplayPackage)

var song: HBSong

enum FilterMode {
	## Show all replays
	FILTER_ALL,
	## Show autosaved replays
	FILTER_AUTOSAVE,
	## Show manually saved replays
	FILTER_SAVED
}

@export var filter_mode: FilterMode = FilterMode.FILTER_ALL

const CONTAINER_ITEM := preload("res://menus/replay_container/ReplayContainerItem.tscn")

func _ready() -> void:
	load_replays()
	focus_mode = FOCUS_ALL
	focus_entered.connect(
		func():
			scroll_list.grab_focus()
	)

func load_replays_from_path(path: String) -> Array[HBReplayPackage]:
	var dir := DirAccess.open(path)
	var replays: Array[HBReplayPackage]
	for file in dir.get_files():
		if file.get_extension() != "phrz":
			continue
		var replay_packaged := HBReplayPackage.new()
		var load_result := replay_packaged.from_file(path.path_join(file))
		if load_result != OK:
			print("Failed to load replay from %s, error code %d" % path.path_join(file), load_result)
			continue
		if song and song.id != replay_packaged.replay_info.game_info.song_id:
			continue
		replays.push_back(replay_packaged)
	return replays

func load_replays():
	for child in item_list.get_children():
		item_list.remove_child(child)
		child.queue_free()
	var load_paths: Array[String]
	if filter_mode == FilterMode.FILTER_ALL or filter_mode == FilterMode.FILTER_AUTOSAVE:
		load_paths.push_back(HBGame.REPLAYS_PATH_AUTOSAVE)
	if filter_mode == FilterMode.FILTER_ALL or filter_mode == FilterMode.FILTER_SAVED:
		load_paths.push_back(HBGame.REPLAYS_PATH)
	
	var replays: Array[HBReplayPackage]
	
	for path in load_paths:
		replays.append_array(load_replays_from_path(path))
	
	replays.sort_custom(
		func (a: HBReplayPackage, b: HBReplayPackage):
			var a_time := a.replay_info.game_info.time
			var b_time := b.replay_info.game_info.time
			return a_time >= b_time
	)
	
	for replay in replays:
		var item: HBReplayContainerItem = CONTAINER_ITEM.instantiate()
		item.replay_package = replay
		item.pressed.connect(replay_selected.emit.bind(replay))
		item_list.add_child(item)
