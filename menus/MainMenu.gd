extends "res://menus/MenuTransitionProvider.gd"

const LOG_NAME = "MainMenu"

var starting_menu = "start_menu"
var starting_menu_args = []
var background_transition_animation_player: AnimationPlayer
var first_background_texrect: TextureRect
var second_background_texrect: TextureRect
var default_bg: Texture = preload("res://graphics/predarkenedbg.png")
var last_bg = 1

const BACKGROUND_TRANSITION_TIME = 0.25 # seconds

func _init():
	MENUS = {
		"start_menu": {
			"fullscreen": preload("res://menus/StartMenu.tscn").instance()
		},
		"main_menu": {
			"left": preload("res://menus/main_menu/MainMenuLeft.tscn").instance(),
			"right": "music_player"
		},
		"lobby_list": {
			"left": preload("res://multiplayer/lobby/LobbyList.tscn").instance()
		},
		"pre_song": {
			"left": preload("res://menus/pregame_screen/PreGameScreen.tscn").instance()
		},
		"lobby": {
			"left": preload("res://multiplayer/lobby/LobbyMenu.tscn").instance(),
			"right": "song_list_preview"
		},
		"song_list_lobby": {
			"left": preload("res://multiplayer/lobby/LobbySongSelector.tscn").instance(),
			"right": "song_list_preview"
		},
		"music_player": {
			"right": preload("res://menus/music_player/MainMenuMusicPlayer.tscn").instance()
		},
		"song_list": {
			"left": preload("res://menus/song_list/SongList.tscn").instance(),
			"right": "song_list_preview"
		},
		"song_list_preview": {
			"right": preload("res://menus/song_list/SongListPreview.tscn").instance()
		},
		"options_menu": {
			"left": preload("res://menus/options_menu/OptionsMenu.tscn").instance()
		},
		"tools_menu": {
			"left": preload("res://menus/tools_menu/ToolsMenu.tscn").instance()
		},
		"results": {
			"left": preload("res://rythm_game/ResultsScreen.tscn").instance(),
			"right": "music_player"
		}
	}



var fullscreen_menu
var left_menu
var right_menu

var fullscreen_menu_container
var left_menu_container
var right_menu_container

var player = AudioStreamPlayer.new()
var voice_player = AudioStreamPlayer.new()

func _ready():
	connect("change_to_menu", self, "_on_change_to_menu")
	menu_setup()
	add_child(player)
	add_child(voice_player)
	MENUS["song_list"].left.connect("song_hovered", self, "play_song")
	
	MENUS["song_list"].left.connect("song_hovered", MENUS["song_list_preview"].right, "select_song")
	MENUS["lobby"].left.connect("song_selected", MENUS["song_list_preview"].right, "select_song")
	player.volume_db = FADE_OUT_VOLUME
	player.bus = "Music"
	voice_player.volume_db = FADE_OUT_VOLUME
	voice_player.bus = "Voice"
	set_process(false)
	MENUS.music_player.right.connect("ready", self, "_on_music_player_ready")
	play_random_song()
	set_process(true)

func menu_setup():
	pass

func _on_change_to_menu(menu_name: String, force_hard_transition=false, args = {}):
	Log.log(self, "Changing to menu " + menu_name)
	var menu_data = MENUS[menu_name]
	
	if left_menu:
		left_menu._on_menu_exit(force_hard_transition)
		left_menu.connect("transition_finished", left_menu_container, "remove_child", [left_menu], CONNECT_ONESHOT)
	if right_menu and menu_data.has("right") and not right_menu == MENUS[menu_data.right].right:
		right_menu._on_menu_exit(force_hard_transition)
		right_menu.connect("transition_finished", right_menu_container, "remove_child", [right_menu], CONNECT_ONESHOT)
	
	if fullscreen_menu:
		fullscreen_menu._on_menu_exit(force_hard_transition)
		fullscreen_menu.connect("transition_finished", fullscreen_menu_container, "remove_child", [fullscreen_menu], CONNECT_ONESHOT)
		fullscreen_menu = null
	if menu_data.has("fullscreen"):
		fullscreen_menu = menu_data["fullscreen"]
		fullscreen_menu_container.add_child(fullscreen_menu)
		fullscreen_menu.connect("change_to_menu", self, "change_to_menu", [], CONNECT_ONESHOT)
		fullscreen_menu._on_menu_enter(force_hard_transition, args)
	if menu_data.has("left"):
		left_menu = menu_data.left
		left_menu_container.add_child(left_menu)
		left_menu.connect("change_to_menu", self, "change_to_menu", [], CONNECT_ONESHOT)
		left_menu._on_menu_enter(force_hard_transition, args)

	if menu_data.has("right"):
		right_menu = MENUS[menu_data.right].right as HBMenu
		if not right_menu in right_menu_container.get_children():
			# Right side of menus are single instance if they are the same
			right_menu_container.add_child(right_menu)
	#		right_menu.connect("change_to_menu", self, "change_to_menu", [], CONNECT_ONESHOT)
			right_menu._on_menu_enter(force_hard_transition, args)

# Audio playback shit

const FADE_OUT_VOLUME = -40
var target_volume = 0
var next_audio: AudioStreamOGGVorbis
var next_voice: AudioStreamOGGVorbis
var current_song: HBSong
var song_queued = false


	
func play_random_song():
	var song = HBSong.new()
	while song.audio == "":
		randomize()
		song = SongLoader.songs.values()[randi() % SongLoader.songs.keys().size()]
	play_song(song)
	
func _process(delta):
	player.volume_db = lerp(player.volume_db, target_volume, 4.0*delta)
	voice_player.volume_db = lerp(player.volume_db, target_volume, 4.0*delta)
	if player.stream and right_menu == MENUS.music_player.right:
		MENUS.music_player.right.set_time(player.get_playback_position())
	if abs(FADE_OUT_VOLUME) - abs(player.volume_db) < 3.0 and song_queued:
		target_volume = 0
		if next_audio:
			player.stream = next_audio
			player.play()
			player.seek(current_song.preview_start/1000.0)
			if next_voice:
				voice_player.stream = next_voice
				voice_player.play()
				voice_player.seek(current_song.preview_start/1000.0)
				song_queued = false
			else:
				voice_player.stream = null
	if player.get_playback_position() >= player.stream.get_length():
		var curr = current_song
		# Ensure random song will always be different from current
		if SongLoader.songs.size() > 1:
			while curr == current_song:
				play_random_song()
		else:
			play_random_song()
func play_song(song: HBSong):
	if song.audio != "":
		if song == current_song:
	#		target_volume = 0
			return
		current_song = song
		next_audio = song.get_audio_stream()
		if song.voice:
			next_voice = song.get_voice_stream()
		else:
			next_voice = null
		target_volume = FADE_OUT_VOLUME
		song_queued = true
		if MENUS.music_player.right == right_menu:
			MENUS.music_player.right.set_song(current_song, next_audio.get_length())
	# Background changes should only happen outside the start menu
	if song.background_image and fullscreen_menu != MENUS["start_menu"].fullscreen:
		var bg_path = song.get_song_background_image_res_path()
		var image = HBUtils.image_from_fs(bg_path)
		var image_texture = ImageTexture.new()
		image_texture.create_from_image(image, Texture.FLAGS_DEFAULT)
		change_to_background(image_texture)
	else:
		change_to_background(null, true)
func _on_music_player_ready():
	call_deferred("play_first_song")

func play_first_song():
	MENUS.music_player.right.set_song(current_song, next_audio.get_length())

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
