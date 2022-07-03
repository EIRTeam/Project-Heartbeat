# Main Game class
extends Node

var demo_mode = false

var game_modes: Array
var rich_presence: HBRichPresence
var song_stats: HBSongStatsLoader
var platform_settings: HBPlatformSettings

var force_steam_deck_mode := "--force-steam-deck" in OS.get_cmdline_args()

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

# HACK HACK HACK, because using load() on multiple thread is more broken than my
# love life we have to put this here, it's also much faster if it's already loaded
var serializable_types = {
	"Note": load("res://scripts/timing_points/HBNoteData.gd"),
	"TimingPoint": load("res://scripts/timing_points/HBTimingPoint.gd"),
	"DoubleNote": load("res://scripts/timing_points/HBDoubleNote.gd"),
	"SustainNote": load("res://scripts/timing_points/HBSustainNote.gd"),
	"BpmChange": load("res://scripts/timing_points/HBBPMChange.gd"),
	"Song": load("res://scripts/HBSong.gd"),
	"Result": load("res://scripts/HBResult.gd"),
	"UserSettings": load("res://scripts/HBUserSettings.gd"),
	"PerSongEditorSettings": load("res://scripts/HBPerSongEditorSettings.gd"),
	"GameInfo": load("res://scripts/HBGameInfo.gd"),
	"NightcoreSettings": load("res://rythm_game/modifiers/nightcore/nightcore_settings.gd"),
	"RandomizerSettings": load("res://rythm_game/modifiers/randomizer/randomizer_settings.gd"),
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
}

const EXCELLENT_THRESHOLD = 0.95
const GREAT_THRESHOLD = 0.90
const PASS_THRESHOLD = 0.75

onready var has_mp4_support = "mp4" in ResourceLoader.get_recognized_extensions_for_type('VideoStreamGDNative')

const MENU_PRESS_SFX = "menu_press"
const ROLLBACK_SFX = "rollback"
const MENU_FORWARD_SFX = "menu_forward"
const MENU_BACK_SFX = "menu_back"
const MENU_VALIDATE_SFX = "menu_validate"
const GAME_OVER_SFX = "game_over"

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
	
var spectrum_analyzer: ShinobuGodotEffectSpectrumAnalyzer
	
func _register_basic_sfx():
	ShinobuGodot.register_group("music")
	ShinobuGodot.register_group("sfx")
	ShinobuGodot.register_group("menu_music", "music")
	spectrum_analyzer = ShinobuGodot.instantiate_spectrum_analyzer()
	spectrum_snapshot.analyzer = spectrum_analyzer
	ShinobuGodot.connect_group_to_effect("music", spectrum_analyzer)
	ShinobuGodot.register_sound_from_path("res://sounds/sfx/274199__littlerobotsoundfactory__ui-electric-08.wav", MENU_PRESS_SFX)
	ShinobuGodot.register_sound_from_path("res://sounds/sfx/flashback.wav", ROLLBACK_SFX)
	ShinobuGodot.register_sound_from_path("res://sounds/sfx/menu_select.wav", MENU_FORWARD_SFX)
	ShinobuGodot.register_sound_from_path("res://sounds/sfx/menu_back.wav", MENU_BACK_SFX)
	ShinobuGodot.register_sound_from_path("res://sounds/sfx/menu_validate.wav", MENU_VALIDATE_SFX)
	ShinobuGodot.register_sound_from_path("res://sounds/sfx/game_over.ogg", GAME_OVER_SFX)
	
func _register_ui_component(component: GDScript):
	ui_components[component.get_component_id()] = component
	
func _process(delta):
	spectrum_snapshot.decay(delta)

	
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
	_register_basic_sfx()
	# We need to call this again (it's called by _init_user_settings)
	# because shinobu groups were not initialized by that point, which is done in 
	# _register_basic_sfx
	UserSettings.apply_volumes()

	SongLoader.add_song_loader("heartbeat", SongLoaderHB.new())
	SongLoader.add_song_loader("ppd", SongLoaderPPD.new())
	SongLoader.add_song_loader("ppd_ext", load("res://autoloads/song_loader/song_loaders/SongLoaderPPDEXT.gd").new())
	ResourcePackLoader._init_resource_pack_loader()
	# Switch specific stuff
	if platform_settings is HBPlatformSettingsSwitch:
		UserSettings.user_settings.button_prompt_override = "nintendo"
		UserSettings.set_joypad_prompts()
		UserSettings.user_settings.load_all_notes_on_song_start = false
		UserSettings.user_settings.visualizer_enabled = false
		Input.set_use_accumulated_input(false)
		UserSettings.user_settings.content_path = platform_settings.user_dir_redirect(UserSettings.user_settings.content_path)
	if "--disable-async-loading" in OS.get_cmdline_args():
		SongLoader.load_all_songs_meta()
	else:
		SongLoader.call_deferred("load_all_songs_async")
	
	YoutubeDL._init_ytdl()
	
	register_game_mode(HBHeartbeatGameMode.new())
	if not OS.has_feature("mobile") or OS.get_name() == "Switch":
		MobileControls.get_child(0).hide()
		
	rich_presence = HBRichPresence.new()
	if not OS.has_feature("no_rich_presence") and not OS.has_feature("editor"):
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

func is_on_steam_deck() -> bool:
	return force_steam_deck_mode or PlatformService.service_provider.is_steam_deck()

func save_empty_streamer_images():
	var empty_image = Image.new()
	
	var bg_size: Vector2 = HBGame.STREAMER_MODE_BACKGROUND_IMAGE_SIZE
	var preview_size: Vector2 = HBGame.STREAMER_MODE_PREVIEW_IMAGE_SIZE
	empty_image.create(bg_size.x, bg_size.y, false, Image.FORMAT_RGBA8)
	empty_image.fill(Color.transparent)
	empty_image.save_png(STREAMER_MODE_CURRENT_SONG_BG_PATH)
	empty_image.create(preview_size.x, preview_size.y, false, Image.FORMAT_RGBA8)
	empty_image.fill(Color.transparent)
	empty_image.save_png(STREAMER_MODE_CURRENT_SONG_PREVIEW_PATH)
	
	var f := File.new()
	f.open(STREAMER_MODE_CURRENT_SONG_TITLE_PATH, File.WRITE)
	f.store_string("")
	f.close()
