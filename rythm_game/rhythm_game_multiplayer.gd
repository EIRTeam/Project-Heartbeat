extends Control

@onready var rhythm_game_controller = get_node("RhythmGame")
var lobby: HeartbeatSteamLobby: set = set_lobby

const LOG_NAME = "RhythmGameMultiplayer"

var loaded_members = []

var _preloaded_assets

@onready var mp_loading_panel: = get_node("%MPLoadingPanel")
@onready var mp_scoreboard: MultiplayerScoreboard = get_node("%MultiplayerScoreboard")
@onready var mp_scoreboard_container: Control = get_node("%MultiplayerScoreboardContainer")
@onready var loading_member_list: MultiplayerLoadingMemberList = get_node("%MultiplayerLoadingMemberList")

func set_lobby(val):
	lobby = val
	if not rhythm_game_controller.is_connected("user_quit", Callable(lobby, "leave_lobby")):
		rhythm_game_controller.connect("user_quit", Callable(lobby, "leave_lobby"))
	for member in lobby.get_all_members_metadata():
		loading_member_list.add_member(member)

# Lets other peers know that the game is starting, this should only be called by
# the authority
func start_game():
	if lobby:
		start_loading()
	else:
		Log.log(self, "Cannot start a game if lobby isn't set", Log.LogLevel.ERROR)

func _on_all_members_finished_loading():
	pass

func _ready():
	rhythm_game_controller.pause_disabled = true
	rhythm_game_controller.game.health_system_enabled = false
	rhythm_game_controller.prevent_showing_results = true
	rhythm_game_controller.game.connect("note_judged", self._on_note_judged)
	rhythm_game_controller.connect("fade_out_finished", self._on_fade_out_finished)
	rhythm_game_controller.disable_restart()
	rhythm_game_controller.allow_modifiers = false
	rhythm_game_controller.disable_intro_skip = false
	_on_resized()
	resized.connect(self._on_resized)
func _on_resized():
	mp_scoreboard_container.size = size
func start_loading():
	var assets_to_load: Array[SongAssetLoader.ASSET_TYPES] = [
		SongAssetLoader.ASSET_TYPES.CIRCLE_LOGO,
		SongAssetLoader.ASSET_TYPES.BACKGROUND,
		SongAssetLoader.ASSET_TYPES.AUDIO,
		SongAssetLoader.ASSET_TYPES.VOICE,
		SongAssetLoader.ASSET_TYPES.AUDIO_LOUDNESS
	]
	var song: HBSong = SongLoader.songs[lobby.lobby_data.song_id]
	var assets: SongAssetLoader.AssetLoadToken = await SongAssetLoader.request_asset_load(song, assets_to_load).assets_loaded
	_on_song_assets_loaded(assets)

var _assets = {}

func _try_start() -> bool:
	for member in lobby.get_all_members_metadata():
		if member.in_game_data.state != HeartbeatSteamLobby.InGameState.LOADED:
			return false
	get_tree().paused = false
	rhythm_game_controller.start_song()
	mp_loading_panel.hide()
	return true
func _on_song_assets_loaded(assets: SongAssetLoader.AssetLoadToken):
	_assets = assets
	var game_info := HBGameInfo.new()
	game_info.song_id = assets.song.id
	game_info.difficulty = lobby.lobby_data.difficulty
	game_info.variant = lobby.lobby_data.song_variant

	rhythm_game_controller.start_session(game_info, _assets)
	for member in lobby.get_all_members_metadata():
		mp_scoreboard.add_member(member) 
	lobby.connect("game_note_hit", Callable(self, "_on_game_note_hit"))
	mp_scoreboard_container.get_parent().remove_child(mp_scoreboard_container)
	rhythm_game_controller.game.game_ui.under_notes_node.add_child(mp_scoreboard_container)
	get_tree().paused = true
	await get_tree().create_timer(2.0 + randf_range(0, 2.0)).timeout
	lobby.update_in_game_state(HeartbeatSteamLobby.InGameState.LOADED)
	if not _try_start():
		lobby.member_left.connect(func(_member): _try_start())
		for member in lobby.get_all_members_metadata():
			member.in_game_data.updated.connect(_try_start)

func _on_note_judged(judgement_info):
	lobby.send_note_hit(judgement_info.judgement, rhythm_game_controller.game.result.score)
	
var MainMenu = load("res://menus/MainMenu3D.tscn")

func _on_fade_out_finished(game_info: HBGameInfo):
	lobby.notify_game_finished(game_info.result)

	var scene = MainMenu.instantiate()
	get_tree().current_scene.queue_free()
	scene.starting_menu = "results_mp"
	scene.starting_menu_args = {
		"game_info": game_info,
		"hide_retry": true,
		"lobby": lobby
	}
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
