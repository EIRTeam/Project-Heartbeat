extends Node

class_name HBRichPresence

enum RichPresenceStage {
	STAGE_AT_MAIN_MENU,
	STAGE_AT_SONG_LIST,
	STAGE_AT_EDITOR,
	STAGE_AT_EDITOR_SONG,
	STAGE_PLAYING,
	STAGE_MULTIPLAYER_LOBBY,
	STAGE_MULTIPLAYER_PLAYING
}

var current_song: HBSong
var current_difficulty: String
var current_song_variant := -1
var current_start_time := -1
var current_score := 0

var current_stage := RichPresenceStage.STAGE_AT_MAIN_MENU

var providers: Array[HBRichPresenceProvider]

func notify_rich_presence_update():
	for provider in providers:
		provider._update_rich_presence(self)

func notify_at_main_menu():
	current_stage = RichPresenceStage.STAGE_AT_MAIN_MENU
	notify_rich_presence_update()

func notify_at_song_list(song: HBSong):
	assert(song)
	current_stage = RichPresenceStage.STAGE_AT_SONG_LIST
	current_song = song
	notify_rich_presence_update()

func notify_at_editor():
	current_stage = RichPresenceStage.STAGE_AT_EDITOR
	notify_rich_presence_update()

func notify_at_editor_song(song: HBSong, difficulty: String, start_time: int):
	assert(song)
	current_stage = RichPresenceStage.STAGE_AT_SONG_LIST
	current_difficulty = difficulty
	current_song = song
	current_start_time = start_time
	notify_rich_presence_update()

func notify_playing(song: HBSong, difficulty: String, start_time: int, score: int):
	current_stage = RichPresenceStage.STAGE_PLAYING
	current_song = song
	current_difficulty = difficulty
	current_score = score
	current_start_time = start_time
	notify_rich_presence_update()

func notify_multiplayer_lobby():
	current_stage = RichPresenceStage.STAGE_MULTIPLAYER_LOBBY
	notify_rich_presence_update()
func notify_multiplayer_playing(song: HBSong, difficulty: String, start_time: int, score: int):
	assert(song)
	current_stage = RichPresenceStage.STAGE_MULTIPLAYER_PLAYING
	current_song = song
	current_difficulty = difficulty
	current_score = score
	notify_rich_presence_update()

func add_provider(provider: HBRichPresenceProvider):
	var result := provider._init_rich_presence()
	provider.set_meta(&"last_tick_time", 0)
	if result == OK:
		providers.push_back(provider)

func _process(_delta: float) -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	for provider in providers:
		var last_tick_time := provider.get_meta(&"last_tick_time") as float
		if current_time - last_tick_time > provider._get_tick_rate():
			provider._tick()
			provider.set_meta(&"last_tick_time", current_time)

func _init():
	name = "RichPresence"
