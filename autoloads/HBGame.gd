# Main Game class
extends Node

var demo_mode = false

var game_modes: Array
var rich_presence: HBRichPresence
var song_stats: HBSongStatsLoader
var platform_settings: HBPlatformSettings

var force_steam_deck_mode := "--force-steam-deck" in OS.get_cmdline_args()
# Used for uploading/editing official songs
var enable_editor_dev_mode := OS.has_feature("editor") and "--editor-dev-mode" in OS.get_cmdline_args()

enum MMPLUS_ERROR {
	OK,
	NEEDS_RESTART,
	NO_STEAM,
	NOT_OWNED,
	NOT_INSTALLED,
	LOAD_ERROR,
}

var mmplus_error: int = MMPLUS_ERROR.NO_STEAM
var mmplus_loader: SongLoaderDSC

const STREAMER_MODE_CURRENT_SONG_TITLE_PATH := "user://current_song.txt"
const STREAMER_MODE_CURRENT_SONG_BG_PATH := "user://current_song_bg.png"
const STREAMER_MODE_CURRENT_SONG_PREVIEW_PATH := "user://current_song_preview.png"
const STREAMER_MODE_PREVIEW_IMAGE_SIZE := Vector2(512, 512)
const STREAMER_MODE_BACKGROUND_IMAGE_SIZE := Vector2(1920, 1080)

# hack...

var NOTE_TYPE_TO_STRING_MAP = {
	HBNoteData.NOTE_TYPE.UP: "up",
	HBNoteData.NOTE_TYPE.LEFT: "left",
	HBNoteData.NOTE_TYPE.DOWN: "down",
	HBNoteData.NOTE_TYPE.RIGHT: "right",
	HBNoteData.NOTE_TYPE.SLIDE_LEFT: "slide_left",
	HBNoteData.NOTE_TYPE.SLIDE_RIGHT: "slide_right",
	HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT: "slide_chain_piece_left",
	HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT: "slide_chain_piece_right",
	HBNoteData.NOTE_TYPE.HEART: "heart"
}

var NOTE_TYPE_TO_ACTIONS_MAP = {
	HBNoteData.NOTE_TYPE.RIGHT: ["note_right"],
	HBNoteData.NOTE_TYPE.LEFT: ["note_left"],
	HBNoteData.NOTE_TYPE.UP: ["note_up"],
	HBNoteData.NOTE_TYPE.DOWN: ["note_down"],
	HBNoteData.NOTE_TYPE.SLIDE_LEFT: ["slide_left"],
	HBNoteData.NOTE_TYPE.SLIDE_RIGHT: ["slide_right"],
	HBNoteData.NOTE_TYPE.HEART: ["heart_note"]
}

const CHART_DIFFICULTY_TAGS := {
	"0-4": [-INF, 4],
	"4-6": [4, 6],
	"6-8": [6, 8],
	"8-10": [8, 10],
	"10+": [10, INF]
}

var content_dir := ""

# HACK HACK HACK, because using load() on multiple thread is more broken than my
# love life we have to put this here, it's also much faster if it's already loaded
var serializable_types = {
	"Note": load("res://scripts/timing_points/HBNoteData.gd"),
	"TimingPoint": load("res://scripts/timing_points/HBTimingPoint.gd"),
	"DoubleNote": load("res://scripts/timing_points/HBDoubleNote.gd"),
	"SustainNote": load("res://scripts/timing_points/HBSustainNote.gd"),
	"BpmChange": load("res://scripts/timing_points/HBBPMChange.gd"),
	"TimingChange": load("res://scripts/timing_points/HBTimingChange.gd"),
	"Song": load("res://scripts/HBSong.gd"),
	"Result": load("res://scripts/HBResult.gd"),
	"UserSettings": load("res://scripts/HBUserSettings.gd"),
	"PerSongEditorSettings": load("res://scripts/HBPerSongEditorSettings.gd"),
	"GameInfo": load("res://scripts/HBGameInfo.gd"),
	"NightcoreSettings": load("res://rythm_game/modifiers/nightcore/nightcore_settings.gd"),
	"RandomizerSettings": load("res://rythm_game/modifiers/randomizer/randomizer_settings.gd"),
	"AutoplaySettings": load("res://rythm_game/modifiers/autoplay/autoplay_settings.gd"),
	"HiddenSettings": load("res://rythm_game/modifiers/randomizer/randomizer_settings.gd"),
	"PerSongSettings": load("res://scripts/HBPerSongSettings.gd"),
	"SongStats": load("res://scripts/HBSongStats.gd"),
	"Folder": load("res://scripts/HBFolder.gd"),
	"SongCacheEntry": load("res://autoloads/HBSongCacheEntry.gd"),
	"AudioLoudnessCacheEntry": load("res://autoloads/HBAudioLoudnessCacheEntry.gd"),
	"PPDSong": load("res://scripts/HBPPDSong.gd"),
	"WebUserInfo": load("res://scripts/HBWebUserInfo.gd"),
	"Phrase": load("res://rythm_game/lyrics/HBLyricsPhrase.gd"),
	"PhraseStart": load("res://rythm_game/lyrics/HBLyricsPhraseStart.gd"),
	"PhraseEnd": load("res://rythm_game/lyrics/HBLyricsPhraseEnd.gd"),
	"Lyric": load("res://rythm_game/lyrics/HBLyricsLyric.gd"),
	"TimingModifierSettings": load("res://rythm_game/modifiers/timing/timing_settings.gd"),
	"IntroSkipMarker": load("res://scripts/timing_points/HBIntroSkipMarker.gd"),
	"HBResourcePack": load("res://tools/resource_pack_editor/HBResourcePack.gd"),
	"HBAtlasEntry": load("res://tools/resource_pack_editor/HBAtlasEntry.gd"),
	"PPDSongEXT": load("res://autoloads/song_loader/song_loaders/HBPPDSongEXT.gd"),
	"HBHistoryEntry": load("res://scripts/HBHistoryEntry.gd"),
	"HBSongVariantData": load("res://scripts/HBSongVariantData.gd"),
	"ChartSection": load("res://scripts/timing_points/HBChartSection.gd"),
	"SkinResources": load("res://scripts/new_ui/HBSkinResources.gd"),
	"Skin": load("res://scripts/new_ui/HBUISkin.gd"),
	"SkinScreen": load("res://scripts/new_ui/HBUISkinScreen.gd"),
	"EditorTemplate": load("res://scripts/HBEditorTemplate.gd")
}

const EXCELLENT_THRESHOLD = 0.95
const GREAT_THRESHOLD = 0.90
const PASS_THRESHOLD = 0.75

@onready var has_mp4_support = "mp4" in ResourceLoader.get_recognized_extensions_for_type('VideoStreamGDNative')

var menu_press_sfx: ShinobuSoundSourceMemory
var rollback_sfx: ShinobuSoundSourceMemory
var menu_forward_sfx: ShinobuSoundSourceMemory
var menu_back_sfx: ShinobuSoundSourceMemory
var menu_validate_sfx: ShinobuSoundSourceMemory
var game_over_sfx: ShinobuSoundSourceMemory

var music_group: ShinobuGroup
var sfx_group: ShinobuGroup
var menu_music_group: ShinobuGroup

var fire_and_forget_sounds := []

const BUTTON_SFX_TYPE_FORWARD = 0
const BUTTON_SFX_TYPE_BACK = 0

var ui_components := {}

var fallback_font: HBUIFont = preload("res://fonts/skined_fallback_font.tres")

const SPECTRUM_DEFINITION = 256

var spectrum_snapshot: HBSpectrumSnapshot

func _ready():
	spectrum_snapshot = HBSpectrumSnapshot.new(SPECTRUM_DEFINITION)
	_game_init()
	if "--demo-mode" in OS.get_cmdline_args():
		demo_mode = true
	add_child(spectrum_snapshot)
	
var spectrum_analyzer: ShinobuSpectrumAnalyzerEffect
	
func register_sound_from_path(name_hint: String, path: String) -> ShinobuSoundSourceMemory:
	var f := FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		prints("Oh cock, error registering sound from path!", path)
	return Shinobu.register_sound_from_memory(name_hint, f.get_buffer(f.get_length()))
	
func fire_and_forget_sound(source: ShinobuSoundSource, group: ShinobuGroup):
	var instance := source.instantiate(group)
	add_child(instance)
	instance.start()
	instance.process_mode = Node.PROCESS_MODE_ALWAYS
	fire_and_forget_sounds.append(instance)
	
func _register_basic_sfx():
	music_group = Shinobu.create_group("music", null)
	sfx_group = Shinobu.create_group("sfx", null)
	menu_music_group = Shinobu.create_group("menu_music", music_group)
	spectrum_analyzer = Shinobu.instantiate_spectrum_analyzer_effect()
	spectrum_snapshot.analyzer = spectrum_analyzer
	music_group.connect_to_effect(spectrum_analyzer)
	spectrum_analyzer.connect_to_endpoint()
	
	menu_press_sfx = register_sound_from_path("menu_press", "res://sounds/sfx/274199__littlerobotsoundfactory__ui-electric-08.wav")
	rollback_sfx = register_sound_from_path("rollback", "res://sounds/sfx/flashback.wav")
	menu_forward_sfx = register_sound_from_path("menu_forward", "res://sounds/sfx/menu_select.wav")
	menu_back_sfx = register_sound_from_path("menu_back", "res://sounds/sfx/menu_back.wav")
	menu_validate_sfx = register_sound_from_path("menu_validate", "res://sounds/sfx/menu_validate.wav")
	game_over_sfx = register_sound_from_path("game_over", "res://sounds/sfx/game_over.ogg")
	
func _register_ui_component(component: GDScript):
	ui_components[component.get_component_id()] = component
	
func _process(delta):
	if UserSettings.user_settings.visualizer_enabled:
		spectrum_snapshot.decay(delta)
	
	for i in range(fire_and_forget_sounds.size()-1, -1, -1):
		var sound := fire_and_forget_sounds[i] as ShinobuSoundPlayer
		if sound.is_at_stream_end():
			sound.queue_free()
		fire_and_forget_sounds.remove_at(i)

	
func _register_ui_components():
	_register_ui_component(HBUISongProgress)
	_register_ui_component(HBUIPanel)
	_register_ui_component(HBUIAccuracyDisplay)
	_register_ui_component(HBUICosmeticTextureRect)
	_register_ui_component(HBUISongTitle)
	_register_ui_component(HBUISongDifficultyLabel)
	_register_ui_component(HBUIScoreCounter)
	_register_ui_component(HBUIClearBar)
	_register_ui_component(HBUISkipIntroIndicator)
	_register_ui_component(HBUIHoldIndicator)
	_register_ui_component(HBUIMultiHint)
	_register_ui_component(HBUIHealthDisplay)
	
func _game_init():
	_register_ui_components()
	if OS.get_name() == "Switch":
		platform_settings = HBPlatformSettingsSwitch.new()
	elif OS.has_feature("mobile"):
		platform_settings = HBPlatformSettingsMobile.new()
	else:
		platform_settings = HBPlatformSettingsDesktop.new()
	PlatformService._initialize_platform()
	
	SongDataCache.load_cache()

	var args := OS.get_cmdline_args() as Array
	# --phplugin:dscloader:game_location=""
	var dsc_game_type = "FT"
	var dsc_g_i = args.find("--phplugin:dscloader:game_type")
	if dsc_g_i != -1 and dsc_g_i < args.size()-1:
		var candidate_gt = args[dsc_g_i+1]
		if not candidate_gt in ["FT", "f"]:
			push_error("Argument game_type must be FT or f")
		else:
			dsc_game_type = candidate_gt
	for i in range(args.size()):
		if args[i].begins_with("--phplugin:dscloader:game_location"):
			if args.size() > i+1:
				var aft_location := args[i+1] as String
				if aft_location.begins_with("\"") and aft_location.ends_with("\""):
					aft_location = aft_location.substr(1, aft_location.length()-2)
				var dsc_loader = preload("res://autoloads/song_loader/song_loaders/SongLoaderDSC.gd").new() as SongLoaderDSC
				dsc_loader.GAME_LOCATION = aft_location
				dsc_loader.game_type = dsc_game_type
				SongLoader.add_song_loader("dsc", dsc_loader)
			else:
				push_error("Argument game_location requires an input")

	UserSettings._init_user_settings()
	
	if not DirAccess.dir_exists_absolute(UserSettings.user_settings.content_path):
		content_dir = "user://"
		print("Content dir does not exist, falling back to user://")
	else:
		content_dir = UserSettings.user_settings.content_path
	
	_register_basic_sfx()
	# We need to call this again (it's called by _init_user_settings)
	# because shinobu groups were not initialized by that point, which is done in 
	# _register_basic_sfx
	UserSettings.apply_volumes()

	SongLoader.init_song_loader()
	SongLoader.add_song_loader("heartbeat", SongLoaderHB.new())
	SongLoader.add_song_loader("ppd", SongLoaderPPD.new())
	SongLoader.add_song_loader("ppd_ext", load("res://autoloads/song_loader/song_loaders/SongLoaderPPDEXT.gd").new())
	ResourcePackLoader._init_resource_pack_loader()
	
	PlatformService.service_provider._post_game_init()
	
	# Switch specific stuff
	if platform_settings is HBPlatformSettingsSwitch:
		UserSettings.user_settings.button_prompt_override = "nintendo"
		UserSettings.set_joypad_prompts()
		UserSettings.user_settings.visualizer_enabled = false
		Input.set_use_accumulated_input(false)
		UserSettings.user_settings.content_path = platform_settings.user_dir_redirect(UserSettings.user_settings.content_path)
	if "--disable-async-loading" in OS.get_cmdline_args():
		SongLoader.load_all_songs_meta()
	else:
		SongLoader.call_deferred("load_all_songs_async")
	
	YoutubeDL._init_ytdl()
	
	register_game_mode(HBHeartbeatGameMode.new())
		
	rich_presence = HBRichPresence.new()
	if not OS.has_feature("no_rich_presence") and not OS.has_feature("editor"):
		rich_presence = HBRichPresenceDiscord.new()
	var res = rich_presence.init_presence()
	if res != OK:
		rich_presence = HBRichPresence.new()
	add_child(rich_presence)

	song_stats = HBSongStatsLoader.new()
	song_stats._init_song_stats()
	if not DirAccess.dir_exists_absolute(UserSettings.CUSTOM_SOUND_PATH):
		DirAccess.make_dir_recursive_absolute(UserSettings.CUSTOM_SOUND_PATH)
	
func register_game_mode(game_mode: HBGameMode):
	game_modes.append(game_mode)
	
func get_game_mode_for_song(song: HBSong):
	for game_mode in game_modes:
		if song.get_serialized_type() in game_mode.get_serializable_song_types():
			return game_mode
	return ERR_FILE_NOT_FOUND

func is_on_steam_deck() -> bool:
	return force_steam_deck_mode or PlatformService.service_provider.is_steam_deck()

func save_empty_streamer_images():
	var empty_image: Image
	
	var bg_size: Vector2 = HBGame.STREAMER_MODE_BACKGROUND_IMAGE_SIZE
	var preview_size: Vector2 = HBGame.STREAMER_MODE_PREVIEW_IMAGE_SIZE
	empty_image = Image.create(bg_size.x, bg_size.y, false, Image.FORMAT_RGBA8)
	empty_image.fill(Color.TRANSPARENT)
	empty_image.save_png(STREAMER_MODE_CURRENT_SONG_BG_PATH)
	empty_image = Image.create(preview_size.x, preview_size.y, false, Image.FORMAT_RGBA8)
	empty_image.fill(Color.TRANSPARENT)
	empty_image.save_png(STREAMER_MODE_CURRENT_SONG_PREVIEW_PATH)
	
	var f := FileAccess.open(STREAMER_MODE_CURRENT_SONG_TITLE_PATH, FileAccess.WRITE)
	f.store_string("")
	f.close()

func get_system_mmplus_error() -> String:
	var out := tr("Unknown error")
	match mmplus_error:
		MMPLUS_ERROR.LOAD_ERROR:
			out = tr("Fatal error loading data from the game, please see below")
		MMPLUS_ERROR.NOT_INSTALLED:
			out = tr("Steam reports MM+ is not installed")
		MMPLUS_ERROR.NOT_OWNED:
			out = tr("Your steam account does not own MM+")
		MMPLUS_ERROR.NO_STEAM:
			out = tr("Steam couldn't be found, is it closed?")
	return out
	
func instantiate_user_sfx(sfx_name: String) -> ShinobuSoundPlayer:
	var sound_source := UserSettings.user_sfx[sfx_name] as ShinobuSoundSource
	var sound := sound_source.instantiate(HBGame.sfx_group)
	sound.volume = UserSettings.user_settings.get_sound_volume_linear(sfx_name)
	return sound
