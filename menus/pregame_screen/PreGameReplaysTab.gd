extends TabbedContainerTab

class_name HBPreGameReplaysTab

var song: HBSong

signal replay_selected(replay: HBReplayPackage)

@onready var replay_container: HBReplayContainer = get_node("%ReplayContainer")

func _enter_tab():
	replay_container.song = song
	replay_container.load_replays()
	replay_container.grab_focus()
	replay_container.replay_selected.connect(replay_selected.emit)
