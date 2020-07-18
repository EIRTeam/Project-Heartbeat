# Main Game class
extends Node

var game_modes: Array
var rich_presence: HBRichPresence

var NOTE_TYPE_TO_ACTIONS_MAP = {
	HBNoteData.NOTE_TYPE.RIGHT: ["note_right"],
	HBNoteData.NOTE_TYPE.LEFT: ["note_left"],
	HBNoteData.NOTE_TYPE.UP: ["note_up"],
	HBNoteData.NOTE_TYPE.DOWN: ["note_down"],
	HBNoteData.NOTE_TYPE.SLIDE_LEFT: ["tap_left"],
	HBNoteData.NOTE_TYPE.SLIDE_RIGHT: ["tap_right"],
	HBNoteData.NOTE_TYPE.HEART: ["tap_up", "tap_down", "tap_left", "tap_right"]
}

func _ready():
	_game_init()
	
func _game_init():
	PlatformService._initialize_platform()

	SongLoader.add_song_loader("heartbeat", SongLoaderHB.new())
	SongLoader.add_song_loader("ppd", SongLoaderPPD.new())
	
	SongLoader.load_all_songs_meta()
	
	YoutubeDL._init_ytdl()

	IconPackLoader._init_icon_pack_loader()
	UserSettings._init_user_settings()
	
	register_game_mode(HBHeartbeatGameMode.new())
	
	rich_presence = HBRichPresenceDiscord.new()
	var res = rich_presence.init_presence()
	if res != OK:
		rich_presence = HBRichPresence.new()
	add_child(rich_presence)
	

func register_game_mode(game_mode: HBGameMode):
	game_modes.append(game_mode)
	
func get_game_mode_for_song(song: HBSong):
	for game_mode in game_modes:
		if song.get_serialized_type() in game_mode.get_serializable_song_types():
			return game_mode
	return ERR_FILE_NOT_FOUND

