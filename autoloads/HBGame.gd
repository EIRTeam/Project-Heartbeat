# Main Game class
extends Node

var game_modes: Array

func _ready():
	_game_init()
	
func _game_init():
	PlatformService._initialize_platform()

	print("Project Heartbeat is on startup...")
	print(HBVersion.get_version_string())

	SongLoader.add_song_loader("heartbeat", SongLoaderHB.new())
	SongLoader.add_song_loader("ppd", SongLoaderPPD.new())
	
	SongLoader.load_all_songs_meta()
	
	YoutubeDL._init_ytdl()

	IconPackLoader._init_icon_pack_loader()
	UserSettings._init_user_settings()
	
	register_game_mode(HBHeartbeatGameMode.new())

func register_game_mode(game_mode: HBGameMode):
	game_modes.append(game_mode)
	
func get_game_mode_for_song(song: HBSong):
	for game_mode in game_modes:
		if song.get_serialized_type() in game_mode.get_serializable_song_types():
			return game_mode
	return ERR_FILE_NOT_FOUND
