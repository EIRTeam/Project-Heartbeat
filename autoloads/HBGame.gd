# Main Game class
extends Node

var demo_mode = false

var game_modes: Array
var rich_presence: HBRichPresence
var song_stats: HBSongStatsLoader
var NOTE_TYPE_TO_ACTIONS_MAP = {
	HBNoteData.NOTE_TYPE.RIGHT: ["note_right"],
	HBNoteData.NOTE_TYPE.LEFT: ["note_left"],
	HBNoteData.NOTE_TYPE.UP: ["note_up"],
	HBNoteData.NOTE_TYPE.DOWN: ["note_down"],
	HBNoteData.NOTE_TYPE.SLIDE_LEFT: ["slide_left"],
	HBNoteData.NOTE_TYPE.SLIDE_RIGHT: ["slide_right"],
	HBNoteData.NOTE_TYPE.HEART: ["heart_note"]
}
func _ready():
	_game_init()
	if "--demo-mode" in OS.get_cmdline_args():
		demo_mode = true
	
func _game_init():
	PlatformService._initialize_platform()
	SongDataCache.load_cache()
	SongLoader.add_song_loader("heartbeat", SongLoaderHB.new())
	SongLoader.add_song_loader("ppd", SongLoaderPPD.new())
	#SongLoader.add_song_loader("aft", preload("res://autoloads/song_loader/song_loaders/SongLoaderDIVA.gd").new())
	
	if OS.has_feature("switch"):
		UserSettings.user_settings.button_prompt_override = "nintendo"
		UserSettings.set_joypad_prompts()
		Input.set_use_accumulated_input(false)
		UserSettings.user_settings.content_path = "sdmc:/switch"
	
	SongLoader.load_all_songs_async()
	
	YoutubeDL._init_ytdl()

	IconPackLoader._init_icon_pack_loader()
	UserSettings._init_user_settings()
	
	register_game_mode(HBHeartbeatGameMode.new())
	if not OS.has_feature("mobile") or OS.has_feature("switch"):
		MobileControls.get_child(0).hide()

	if OS.has_feature("no_rich_presence"):
		rich_presence = HBRichPresence.new()
	else:
		rich_presence = HBRichPresenceDiscord.new()
	var res = rich_presence.init_presence()
	if res != OK:
		rich_presence = HBRichPresence.new()
	add_child(rich_presence)

	song_stats = HBSongStatsLoader.new()
	song_stats._init_song_stats()
	var dir := Directory.new()
	if not dir.dir_exists(UserSettings.CUSTOM_SOUND_PATH):
		dir.make_dir_recursive(UserSettings.CUSTOM_SOUND_PATH)
	

func register_game_mode(game_mode: HBGameMode):
	game_modes.append(game_mode)
	
func get_game_mode_for_song(song: HBSong):
	for game_mode in game_modes:
		if song.get_serialized_type() in game_mode.get_serializable_song_types():
			return game_mode
	return ERR_FILE_NOT_FOUND

