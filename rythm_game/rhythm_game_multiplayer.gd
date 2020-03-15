extends Control

onready var rhythm_game_controller = get_node("RhythmGame")
var lobby: HBLobby setget set_lobby

const LOG_NAME = "RhythmGameMultiplayer"

var loaded_members = []

var background_song_assets_loader = HBBackgroundSongAssetsLoader.new()

var _preloaded_assets

onready var mp_loading_label = get_node("MPLoadingLabel")
onready var mp_scoreboard = get_node("Control/MultiplayerScoreboard")
func set_lobby(val):
	lobby = val

# Lets other peers know that the game is starting, this should only be called by
# the authority
func start_game():
	if lobby:
		lobby.start_session()
		# Hook up authority specific lobby signals
		lobby.connect("game_member_loading_finished", self, "_on_game_member_loading_finished")
		lobby.connect("game_note_hit", self, "_on_game_note_hit")
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

func start_loading():
	background_song_assets_loader.connect("song_assets_loaded", self, "_on_song_assets_loaded")
	background_song_assets_loader.load_song_assets(lobby.get_song(), ["circle_logo", "background", "audio", "voice"])
	lobby.connect("game_start", self, "_on_game_started")
	lobby.connect("game_done", self, "_on_game_done")
	lobby.connect("member_left", mp_scoreboard, "remove_member")

func _on_song_assets_loaded(song, assets):
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

func _on_game_done(results):
	for member in results:
		print("Game done for ", member.get_member_name())
