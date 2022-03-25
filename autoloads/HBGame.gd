# Main Game class
extends Node

var demo_mode = false

var game_modes: Array
var rich_presence: HBRichPresence
var song_stats: HBSongStatsLoader
var platform_settings: HBPlatformSettings

var force_steam_deck_mode := "--force-steam-deck" in OS.get_cmdline_args()

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

const BUTTON_SFX_TYPE_FORWARD = 0
const BUTTON_SFX_TYPE_BACK = 0

func _ready():
	_game_init()
	if "--demo-mode" in OS.get_cmdline_args():
		demo_mode = true
	
func _register_basic_sfx():
	ShinobuGodot.register_group("sfx")
	ShinobuGodot.register_group("music")
	ShinobuGodot.register_group("menu_music")
	ShinobuGodot.register_sound_from_path("res://sounds/sfx/274199__littlerobotsoundfactory__ui-electric-08.wav", MENU_PRESS_SFX)
	ShinobuGodot.register_sound_from_path("res://sounds/sfx/flashback.wav", ROLLBACK_SFX)
	ShinobuGodot.register_sound_from_path("res://sounds/sfx/menu_select.wav", MENU_FORWARD_SFX)
	ShinobuGodot.register_sound_from_path("res://sounds/sfx/menu_back.wav", MENU_BACK_SFX)
	ShinobuGodot.register_sound_from_path("res://sounds/sfx/menu_validate.wav", MENU_VALIDATE_SFX)
	
func _game_init():
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
#	if not OS.has_feature("no_rich_presence"):
#		rich_presence = HBRichPresenceDiscord.new()
#	var res = rich_presence.init_presence()
#	if res != OK:
#		rich_presence = HBRichPresence.new()
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
