extends Control

onready var rhythm_game_controller = get_node("RhythmGame")
var lobby: HBLobby setget set_lobby

const LOG_NAME = "RhythmGameMultiplayer"

var loaded_members = []

var background_song_assets_loader = HBBackgroundSongAssetsLoader.new()

var _preloaded_assets

onready var mp_loading_label = get_node("MPLoadingLabel")
onready var mp_scoreboard = get_node("Node2D/MultiplayerScoreboard")
func set_lobby(val):
	lobby = val
	if not rhythm_game_controller.is_connected("user_quit", lobby, "leave_lobby"):
		rhythm_game_controller.connect("user_quit", lobby, "leave_lobby")

# Lets other peers know that the game is starting, this should only be called by
# the authority
func start_game():
	if lobby:
		lobby.start_session()
		# Hook up authority specific lobby signals
		lobby.connect("game_member_loading_finished", self, "_on_game_member_loading_finished")
		start_loading()
	else:
		Log.log(self, "Cannot start a game if lobby isn't set", Log.LogLevel.ERROR)

func _on_all_members_finished_loading():
	pass

func _ready():
	rhythm_game_controller.pause_disabled = true
	rhythm_game_controller.prevent_showing_results = true
	rhythm_game_controller.game.connect("note_judged", self, "_on_note_judged")
	rhythm_game_controller.connect("fade_out_finished", self, "_on_fade_out_finished")
	rhythm_game_controller.disable_restart()
	rhythm_game_controller.allow_modifiers = false
	rhythm_game_controller.disable_intro_skip = false
	_on_resized()
	connect("resized", self, "_on_resized")
func _on_resized():
	mp_scoreboard.rect_size.y = rect_size.y
	mp_scoreboard.rect_position.x = rect_size.x - mp_scoreboard.rect_size.x
func start_loading():
	var task = SongAssetLoadAsyncTask.new(["circle_logo", "background", "audio", "voice", "audio_loudness", "do_dsc_audio_split"], lobby.get_song())
	task.connect("assets_loaded", self, "_on_song_assets_loaded")
	lobby.connect("game_start", self, "_on_game_started")
	lobby.connect("game_done", self, "_on_game_done")
	lobby.connect("member_left", mp_scoreboard, "remove_member")

func _on_song_assets_loaded(assets):
	# Authority doesn't have to send a packet...
	if lobby.is_owned_by_local_user():
		for member in lobby.members.values():
			if member.is_local_user():
				_on_game_member_loading_finished(member)
	else:
		lobby.notify_game_loaded()
		
func _on_game_started(game_info: HBGameInfo):
	rhythm_game_controller.start_session(game_info)
	mp_scoreboard.members = lobby.members.values()
	mp_loading_label.hide()
	lobby.connect("game_note_hit", self, "_on_game_note_hit")
# Called when a client has finished loading the song (this includes authority)
func _on_game_member_loading_finished(member: HBServiceMember):
	loaded_members.append(member)
	if lobby.is_owned_by_local_user():
		if loaded_members.size() >= lobby.member_count:
			lobby.start_game()
			_on_game_started(lobby.game_info)

func _on_game_note_hit(member, score, rating):
	mp_scoreboard.set_last_note_hit_for_member(member, score, rating)

func _on_note_judged(judgement_info):
	var score = rhythm_game_controller.game.result.get_capped_score()
	for member in lobby.members.values():
		if member.is_local_user():
			_on_game_note_hit(member, score, judgement_info.judgement)
	lobby.send_note_hit_update(score, judgement_info.judgement)
	
func _on_fade_out_finished(game_info: HBGameInfo):
	lobby.notify_game_finished(game_info.result)

var MainMenu = load("res://menus/MainMenu3D.tscn")

func _on_game_done(results, game_info):
	var scene = MainMenu.instance()
	get_tree().current_scene.queue_free()
	scene.starting_menu = "results"
	scene.starting_menu_args = {
		"game_info": game_info,
		"hide_retry": true,
		"mp_entries": results,
		"lobby": lobby
	}
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
