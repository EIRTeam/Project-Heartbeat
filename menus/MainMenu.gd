extends "res://menus/MenuTransitionProvider.gd"

class_name HBMainMenu

var starting_menu = "start_menu"
var starting_menu_args = []
var background_transition_animation_player: AnimationPlayer
var first_background_texrect: TextureRect
var second_background_texrect: TextureRect
var music_player_control
var default_bg: Texture2D = preload("res://graphics/predarkenedbg.png")
var last_bg = 1
var starting_song: HBSong
var visualizer: Control
var bar_visualizer: Control
var current_bg_song: HBSong

const BACKGROUND_TRANSITION_TIME = 0.25 # seconds

func _init():
	LOG_NAME = "MainMenu"
	MENUS = {
		"start_menu": {
			"fullscreen": preload("res://menus/StartMenu.tscn").instantiate()
		},
		"switch_premenu": {
			"left": preload("res://menus/demo_screen/SwitchScreen.tscn").instantiate(),
		},
		"demo_premenu": {
			"left": preload("res://menus/demo_screen/DemoScreen.tscn").instantiate(),
		},
		"main_menu": {
			"left": preload("res://menus/main_menu/MainMenuLeft.tscn").instantiate(),
			"right": "main_menu_right"
		},
		"main_menu_right": {
			"right": preload("res://menus/news_list/MainMenuRight.tscn").instantiate()
		},
		"lobby_list": {
			"left": preload("res://multiplayer/lobby/LobbyList.tscn").instantiate()
		},
		"pre_game": {
			"left": preload("res://menus/pregame_screen/PreGameScreen.tscn").instantiate(),
			"right": "mp_leaderboard"
		},
		"download_queue" : {
			"left": preload("res://menus/media_download_queue/MediaDownloadQueue.tscn").instantiate(),
			"right": "empty"
		},
		"lobby": {
			"left": preload("res://multiplayer/lobby/LobbyMenu.tscn").instantiate(),
			"right": "song_list_preview"
		},
		"song_list_lobby": {
			"left": preload("res://multiplayer/lobby/LobbySongSelector.tscn").instantiate(),
			"right": "song_list_preview"
		},
		"mp_leaderboard": {
			"right": preload("res://menus/RightLeaderboard.tscn").instantiate()
		},
		"song_list": {
			"left": preload("res://menus/song_list/SongList.tscn").instantiate(),
			"right": "song_list_preview"
		},
		"song_list_preview": {
			"right": preload("res://menus/song_list/SongListPreview.tscn").instantiate()
		},
		"options_menu": {
			"left": preload("res://menus/options_menu/OptionsMenu.tscn").instantiate(),
			"right": "empty"
		},
		"tools_menu": {
			"left": preload("res://menus/tools_menu/ToolsMenu.tscn").instantiate(),
			"right": "empty"
		},
		"results": {
			"left": preload("res://rythm_game/ResultsScreen.tscn").instantiate(),
			"right": "song_list_preview"
		},
		"results_mp": {
			"left": preload("res://rythm_game/ResultsScreen.tscn").instantiate(),
			"right": "mp_leaderboard"
		},
		"staff_roll": {
			"left": preload("res://menus/credits/Credits.tscn").instantiate()
		},
		"tutorial": {
			"fullscreen": preload("res://menus/tutorial/TutorialScreen.tscn").instantiate(),
			"right": "empty"
		},
		"empty": {
			"right": preload("res://menus/EmptyRightMenu.gd").new()
		},
		"workshop_browser": {
			"left": preload("res://menus/workshop_browser/WorkshopBrowser.tscn").instantiate(),
			"right": "empty"
		},
		"workshop_browser_detail_view": {
			"left": preload("res://menus/workshop_browser/WorkshopItemDetailView.tscn").instantiate(),
			"right": "empty"
		},
		"latency_tester": {
			"fullscreen": preload("res://tools/latency_tester/LatencyTester.tscn").instantiate(),
			"right": "empty"
		}
	}

var result_menus = ["results", "results_mp"]

var fullscreen_menu
var left_menu
var right_menu

var fullscreen_menu_container

var left_menu_container
var right_menu_container: Control

var player = HBBackgroundMusicPlayer.new()

var user_info_ui
func _ready():
	if UserSettings.user_settings.enable_streamer_mode:
		HBGame.save_empty_streamer_images()
	get_tree().paused = false
	#TODOGD4
	#get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1920, 1080))
	DownloadProgress.holding_back_notifications = false
	connect("changed_to_menu", Callable(self, "_on_change_to_menu"))
	add_child(player)
	MENUS["song_list"].left.connect("song_hovered", Callable(player, "play_song"))
	MENUS["lobby"].left.connect("song_selected", Callable(player, "play_song"))

	MENUS["song_list_lobby"].left.connect("song_hovered", Callable(MENUS["song_list_preview"].right, "select_song"))
	MENUS["song_list_lobby"].left.connect("song_hovered", Callable(player, "play_song"))
	
	MENUS["song_list"].left.connect("song_hovered", Callable(MENUS["song_list_preview"].right, "select_song"))
	MENUS["song_list"].left.connect("song_hovered", Callable(MENUS["pre_game"].left, "select_song"))
	MENUS["lobby"].left.connect("song_selected", Callable(MENUS["song_list_preview"].right, "select_song"))
	#MENUS["results"].left.connect("show_song_results", MENUS["leaderboard"].right.get_leadearboard_control(), "fetch_entries")
	
	MENUS["results"].left.connect("select_song", Callable(MENUS["song_list_preview"].right, "select_song"))
	
	MENUS["results_mp"].left.connect("show_song_results_mp", Callable(MENUS["mp_leaderboard"].right.get_leadearboard_control(), "set_entries"))
	
	#MENUS["pre_game"].left.connect("song_selected", MENUS["leaderboard"].right.get_leadearboard_control(), "set_song")
	MENUS["pre_game"].left.connect("begin_loading", Callable(self, "_on_loading_begun"))
	player.connect("song_started", Callable(self, "_on_song_started"))
	player.connect("stream_time_changed", Callable(self, "_on_song_time_changed"))
	MENUS["song_list_preview"].right.connect("song_assets_loaded", Callable(MENUS["pre_game"].left, "set_current_assets"))
	
	# Connect main menu list changes
	MENUS["main_menu"].left.connect("right", Callable(MENUS["main_menu_right"].right, "_on_right_from_MainMenu"))
	MENUS["main_menu_right"].right.connect("left", Callable(MENUS["main_menu"].left, "_on_left_from_MainMenuRight"))
	
	
	menu_setup()
	MENUS.main_menu.left.connect("menu_entered", Callable(bar_visualizer, "appear"))
	MENUS.main_menu.left.connect("menu_exited", Callable(bar_visualizer, "disappear"))
	
	
	if starting_song:
		player.play_song(starting_song)
	else:
		player.play_random_song()
	
	# Mute bg music when using the latency tester
	MENUS["latency_tester"].fullscreen.connect("pause_background_player", Callable(player, "pause"))
	MENUS["latency_tester"].fullscreen.connect("resume_background_player", Callable(player, "resume"))
	
	SongLoader.connect("all_songs_loaded", Callable(MENUS["song_list"].left, "_on_songs_reloaded"))
	SongLoader.connect("all_songs_loaded", Callable(MENUS["song_list_lobby"].left, "_on_songs_reloaded"))
	
#	MENUS["pre_game"].left.set_background_image(first_background_texrect.texture)

func _on_loading_begun():
	pass

func menu_setup():
	pass

func _on_change_to_menu(menu_name: String, force_hard_transition=false, args = {}):
	Log.log(self, "Changing to menu " + menu_name)
	var menu_data = MENUS[menu_name]
	
	if left_menu:
		left_menu._on_menu_exit(force_hard_transition)
		left_menu.connect("transition_finished", Callable(left_menu_container, "remove_child").bind(left_menu), CONNECT_ONE_SHOT)
	if right_menu and (menu_data.has("right") or menu_data.has("fullscreen")) and (menu_data.has("fullscreen") or not right_menu == MENUS[menu_data.right].right):
		right_menu._on_menu_exit(force_hard_transition)
		right_menu.connect("transition_finished", Callable(right_menu_container, "remove_child").bind(right_menu), CONNECT_ONE_SHOT)
	
	if fullscreen_menu:
		fullscreen_menu._on_menu_exit(force_hard_transition)
		fullscreen_menu.connect("transition_finished", Callable(fullscreen_menu_container, "remove_child").bind(fullscreen_menu), CONNECT_ONE_SHOT)
		fullscreen_menu = null
	if menu_data.has("fullscreen"):
		user_info_ui.hide()
		music_player_control.hide()
		fullscreen_menu = menu_data["fullscreen"]
		fullscreen_menu_container.add_child(fullscreen_menu)
		fullscreen_menu.connect("changed_to_menu", Callable(self, "change_to_menu").bind(), CONNECT_ONE_SHOT)
		fullscreen_menu._on_menu_enter(force_hard_transition, args)
	else:
		user_info_ui.show()
		music_player_control.show()
	if menu_data.has("right"):
		right_menu = MENUS[menu_data.right].right as HBMenu
		# Prevent softlock when transiton hasn't finished
		if right_menu.is_connected("transition_finished", Callable(right_menu_container, "remove_child")):
			right_menu.disconnect("transition_finished", Callable(right_menu_container, "remove_child"))
		if not right_menu in right_menu_container.get_children():
			# Right side of menus are single instance if they are the same
			if not right_menu in right_menu_container.get_children():
				right_menu_container.add_child(right_menu)
	#		right_menu.connect("change_to_menu", self, "change_to_menu", [], CONNECT_ONESHOT)
			right_menu._on_menu_enter(force_hard_transition, args)

	if menu_data.has("left"):
		left_menu = menu_data.left
		# Prevent softlock when transiton hasn't finished
		if left_menu.is_connected("transition_finished", Callable(left_menu_container, "remove_child")):
			left_menu.disconnect("transition_finished", Callable(left_menu_container, "remove_child"))
		if not left_menu in left_menu_container.get_children():
			left_menu_container.add_child(left_menu)

		left_menu.connect("changed_to_menu", Callable(self, "change_to_menu").bind(), CONNECT_ONE_SHOT)
		left_menu._on_menu_enter(force_hard_transition, args)

var iflag = true # Flag that tells it to ignore the first background change
func _on_background_loaded(token: SongAssetLoader.AssetLoadToken):
	var background := token.get_asset(SongAssetLoader.ASSET_TYPES.BACKGROUND)
	if (starting_menu in result_menus) or (not iflag):
		if background and fullscreen_menu != MENUS["start_menu"].fullscreen:
			var mat: ShaderMaterial
			if background is DIVASpriteSet.DIVASprite:
				mat = background.get_material()
			change_to_background(background, false, mat)
		else:
			change_to_background(null, true)
	else:
		iflag = false

func _on_song_started():
	current_bg_song = player.current_song_player.song
	HBGame.spectrum_snapshot.set_volume(player.current_song_player.target_volume)
	music_player_control.set_song(current_bg_song, player.get_current_song_length())
	var token := SongAssetLoader.request_asset_load(current_bg_song, [SongAssetLoader.ASSET_TYPES.BACKGROUND])
	token.assets_loaded.connect(_on_background_loaded)
	
func change_to_background(background: Texture2D, use_default = false, material = null):
	if use_default:
		background = default_bg
	background_transition_animation_player.speed_scale = 1/BACKGROUND_TRANSITION_TIME
	if last_bg == 1:
		second_background_texrect.texture = background
		background_transition_animation_player.play("1to2")
		second_background_texrect.material = material
		last_bg = 2
	else:
		first_background_texrect.texture = background
		first_background_texrect.material = material
		background_transition_animation_player.play_backwards("1to2")
		last_bg = 1

func _on_song_time_changed(time):
	music_player_control.set_time(time)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		for menu in MENUS:
			for submenu in MENUS[menu]:
				if not MENUS[menu][submenu] is String:
					if is_instance_valid(MENUS[menu][submenu]):
						MENUS[menu][submenu].queue_free()
