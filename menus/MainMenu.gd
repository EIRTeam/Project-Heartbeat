extends "res://menus/MenuTransitionProvider.gd"

class_name HBMainMenu

var starting_menu = "start_menu"
var starting_menu_args = []
var background_transition_animation_player: AnimationPlayer
var first_background_texrect: TextureRect
var second_background_texrect: TextureRect
var music_player_control
var default_bg: Texture = preload("res://graphics/predarkenedbg.png")
var last_bg = 1

const BACKGROUND_TRANSITION_TIME = 0.25 # seconds

func _init():
	LOG_NAME = "MainMenu"
	MENUS = {
		"start_menu": {
			"fullscreen": preload("res://menus/StartMenu.tscn").instance()
		},
		"switch_premenu": {
			"left": preload("res://menus/demo_screen/SwitchScreen.tscn").instance(),
		},
		"demo_premenu": {
			"left": preload("res://menus/demo_screen/DemoScreen.tscn").instance(),
		},
		"main_menu": {
			"left": preload("res://menus/main_menu/MainMenuLeft.tscn").instance(),
			"right": "main_menu_right"
		},
		"main_menu_right": {
			"right": preload("res://menus/news_list/MainMenuRight.tscn").instance()
		},
		"lobby_list": {
			"left": preload("res://multiplayer/lobby/LobbyList.tscn").instance()
		},
		"pre_game": {
			"left": preload("res://menus/pregame_screen/PreGameScreen.tscn").instance(),
			"right": "mp_leaderboard"
		},
		"lobby": {
			"left": preload("res://multiplayer/lobby/LobbyMenu.tscn").instance(),
			"right": "song_list_preview"
		},
		"song_list_lobby": {
			"left": preload("res://multiplayer/lobby/LobbySongSelector.tscn").instance(),
			"right": "song_list_preview"
		},
		"mp_leaderboard": {
			"right": preload("res://menus/RightLeaderboard.tscn").instance()
		},
		"song_list": {
			"left": preload("res://menus/song_list/SongList.tscn").instance(),
			"right": "song_list_preview"
		},
		"song_list_preview": {
			"right": preload("res://menus/song_list/SongListPreview.tscn").instance()
		},
		"options_menu": {
			"left": preload("res://menus/options_menu/OptionsMenu.tscn").instance(),
			"right": "empty"
		},
		"tools_menu": {
			"left": preload("res://menus/tools_menu/ToolsMenu.tscn").instance(),
			"right": "empty"
		},
		"results": {
			"left": preload("res://rythm_game/ResultsScreen.tscn").instance(),
			"right": "mp_leaderboard"
		},
		"staff_roll": {
			"left": preload("res://menus/credits/Credits.tscn").instance()
		},
		"tutorial": {
			"fullscreen": preload("res://menus/tutorial/TutorialScreen.tscn").instance(),
			"right": "empty"
		},
		"empty": {
			"right": preload("res://menus/EmptyRightMenu.gd").new()
		}
	}



var fullscreen_menu
var left_menu
var right_menu

var fullscreen_menu_container

var left_menu_container
var right_menu_container: Control

var player = HBBackgroundMusicPlayer.new()

var user_info_ui
func _ready():
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1920, 1080))
	DownloadProgress.holding_back_notifications = false
	connect("change_to_menu", self, "_on_change_to_menu")
	add_child(player)
	MENUS["song_list"].left.connect("song_hovered", player, "play_song")
	MENUS["lobby"].left.connect("song_selected", player, "play_song")

	MENUS["song_list_lobby"].left.connect("song_hovered", MENUS["song_list_preview"].right, "select_song")
	MENUS["song_list_lobby"].left.connect("song_hovered", player, "play_song")
	
	MENUS["song_list"].left.connect("song_hovered", MENUS["song_list_preview"].right, "select_song")
	MENUS["song_list"].left.connect("song_hovered", MENUS["pre_game"].left, "select_song")
	MENUS["lobby"].left.connect("song_selected", MENUS["song_list_preview"].right, "select_song")
	#MENUS["results"].left.connect("show_song_results", MENUS["leaderboard"].right.get_leadearboard_control(), "fetch_entries")
	MENUS["results"].left.connect("show_song_results_mp", MENUS["mp_leaderboard"].right.get_leadearboard_control(), "set_entries")
	#MENUS["pre_game"].left.connect("song_selected", MENUS["leaderboard"].right.get_leadearboard_control(), "set_song")
	MENUS["pre_game"].left.connect("begin_loading", self, "_on_loading_begun")
	player.connect("song_started", self, "_on_song_started")
	player.connect("stream_time_changed", self, "_on_song_time_changed")
	player.play_random_song()
	MENUS["song_list_preview"].right.connect("song_assets_loaded", MENUS["pre_game"].left, "set_current_assets")
	
	# Connect main menu list changes
	MENUS["main_menu"].left.connect("right", MENUS["main_menu_right"].right, "_on_right_from_MainMenu")
	MENUS["main_menu_right"].right.connect("left", MENUS["main_menu"].left, "_on_left_from_MainMenuRight")
	
	menu_setup()
	
	music_player_control.connect("ready", self, "_on_music_player_ready")
	
	SongLoader.connect("all_songs_loaded", MENUS["song_list"].left, "_on_songs_reloaded")
	SongLoader.connect("all_songs_loaded", MENUS["song_list_lobby"].left, "_on_songs_reloaded")
	
#	MENUS["pre_game"].left.set_background_image(first_background_texrect.texture)

func _on_loading_begun():
	player.background_song_assets_loader.force_abort_current_loading()

func menu_setup():
	pass

func _on_change_to_menu(menu_name: String, force_hard_transition=false, args = {}):
	Log.log(self, "Changing to menu " + menu_name)
	var menu_data = MENUS[menu_name]
	
	if left_menu:
		left_menu._on_menu_exit(force_hard_transition)
		left_menu.connect("transition_finished", left_menu_container, "remove_child", [left_menu], CONNECT_ONESHOT)
	if right_menu and (menu_data.has("right") or menu_data.has("fullscreen")) and (menu_data.has("fullscreen") or not right_menu == MENUS[menu_data.right].right):
		right_menu._on_menu_exit(force_hard_transition)
		right_menu.connect("transition_finished", right_menu_container, "remove_child", [right_menu], CONNECT_ONESHOT)
	
	if fullscreen_menu:
		fullscreen_menu._on_menu_exit(force_hard_transition)
		fullscreen_menu.connect("transition_finished", fullscreen_menu_container, "remove_child", [fullscreen_menu], CONNECT_ONESHOT)
		fullscreen_menu = null
	if menu_data.has("fullscreen"):
		user_info_ui.hide()
		music_player_control.hide()
		fullscreen_menu = menu_data["fullscreen"]
		fullscreen_menu_container.add_child(fullscreen_menu)
		fullscreen_menu.connect("change_to_menu", self, "change_to_menu", [], CONNECT_ONESHOT)
		fullscreen_menu._on_menu_enter(force_hard_transition, args)
	else:
		user_info_ui.show()
		music_player_control.show()
	if menu_data.has("right"):
		right_menu = MENUS[menu_data.right].right as HBMenu
		# Prevent softlock when transiton hasn't finished
		if right_menu.is_connected("transition_finished", right_menu_container, "remove_child"):
			right_menu.disconnect("transition_finished", right_menu_container, "remove_child")
		if not right_menu in right_menu_container.get_children():
			# Right side of menus are single instance if they are the same
			if not right_menu in right_menu_container.get_children():
				right_menu_container.add_child(right_menu)
	#		right_menu.connect("change_to_menu", self, "change_to_menu", [], CONNECT_ONESHOT)
			right_menu._on_menu_enter(force_hard_transition, args)

	if menu_data.has("left"):
		left_menu = menu_data.left
		# Prevent softlock when transiton hasn't finished
		if left_menu.is_connected("transition_finished", left_menu_container, "remove_child"):
			left_menu.disconnect("transition_finished", left_menu_container, "remove_child")
		if not left_menu in left_menu_container.get_children():
			left_menu_container.add_child(left_menu)

		left_menu.connect("change_to_menu", self, "change_to_menu", [], CONNECT_ONESHOT)
		left_menu._on_menu_enter(force_hard_transition, args)

func _on_music_player_ready():
	call_deferred("play_first_song")

#func play_first_song():
#	MENUS.music_player.right.set_song(current_song, next_audio.get_length())

var iflag = true # Flag that tells it to ignore the first background change
func _on_song_started(song, assets):
	if "audio" in assets:
		if assets.audio:
			pass
			music_player_control.set_song(song, assets.audio.get_length())
	if not iflag:
		if song.background_image and fullscreen_menu != MENUS["start_menu"].fullscreen and "background" in assets:
			change_to_background(assets.background)
		else:
			change_to_background(null, true)
	else:
		iflag = false
	
func change_to_background(background: Texture, use_default = false):
	if use_default:
		background = default_bg
	background_transition_animation_player.playback_speed = 1/BACKGROUND_TRANSITION_TIME
	if last_bg == 1:
		second_background_texrect.texture = background
		background_transition_animation_player.play("1to2")
		last_bg = 2
	else:
		first_background_texrect.texture = background
		background_transition_animation_player.play_backwards("1to2")
		last_bg = 1

func _on_song_time_changed(time):
	music_player_control.set_time(time)
