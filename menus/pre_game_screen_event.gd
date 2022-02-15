extends HBMenu

var song: HBSong
var difficulty: String
var assets
var song_assets: HBSong

func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	song = args.song
	difficulty = args.difficulty
	$ControllerPrompt.set_note_usage(song.get_chart_note_usage(difficulty))

func set_current_assets(song, _assets):
	if song == song:
		song_assets = song
		assets = _assets

func _input(event):
	if event.is_action_pressed("gui_accept") or event.is_action_pressed("pause"):
		if song_assets == song:
			var new_scene = preload("res://menus/LoadingScreen.tscn")
			var game_info := HBGameInfo.new()
			game_info.time = OS.get_unix_time()
			var scene = new_scene.instance()
			get_tree().current_scene.queue_free()
			get_tree().root.add_child(scene)
			get_tree().current_scene = scene
			game_info.song_id = song.id
			game_info.difficulty = difficulty
			emit_signal("begin_loading")
			scene.load_song(game_info, false, assets)
