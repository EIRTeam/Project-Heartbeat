# Main Game class
extends Node

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
