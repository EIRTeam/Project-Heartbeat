extends HBMenu

var game_info : HBGameInfo: set = set_game_info

@onready var title_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer/SongTitle")
@onready var buttons = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel3/MarginContainer/VBoxContainer")
@onready var return_button = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel3/MarginContainer/VBoxContainer/HBHovereableButton2")
@onready var button_panel = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel3")
@onready var button_container = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel3/MarginContainer/VBoxContainer")
@onready var retry_button = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel3/MarginContainer/VBoxContainer/HBHovereableButton")
@onready var rating_popup = get_node("RatingPopup")
@onready var upvote_button = get_node("RatingPopup/Panel/MarginContainer/VBoxContainer/HBoxContainer/UpvoteButton")
@onready var downvote_button = get_node("RatingPopup/Panel/MarginContainer/VBoxContainer/HBoxContainer/DownvoteButton")
@onready var skip_button = get_node("RatingPopup/Panel/MarginContainer/VBoxContainer/HBoxContainer/SkipButton")
@onready var no_opinion_button = get_node("RatingPopup/Panel/MarginContainer/VBoxContainer/HBoxContainer/NoOpinionButton")
@onready var rating_buttons_container = get_node("RatingPopup/Panel/MarginContainer/VBoxContainer/HBoxContainer")
@onready var copy_result_url_button = get_node("%CopyResultURLButton")
@onready var error_window: HBConfirmationWindow = get_node("ErrorWindow")
@onready var uploading_score_indicator = get_node("%UploadingScoreIndicator")
@onready var uploading_score_indicator_progress_bar: ProgressBar = get_node("%UploadingScoreIndicatorProgressBar")

signal show_song_results_mp(lobby: HeartbeatSteamLobby)
signal select_song(song)

var mp_lobby: HeartbeatSteamLobby
var current_song: HBSong
var current_assets

var score_web_id := -1

@onready var tabbed_container = get_node("MarginContainer/VBoxContainer/VBoxContainer2/TabbedContainer")
@onready var results_tab: HBResultsScreenResultTab = preload("res://rythm_game/results_screen/ResultsScreenResultTab.tscn").instantiate()
@onready var chart_tab = preload("res://rythm_game/results_screen/ResultsScreenGraphTab.tscn").instantiate()
@onready var stats_tab: HBResultsScreenStatsTab = preload("res://rythm_game/results_screen/ResultsScreenStatsTab.tscn").instantiate()
var current_timer: SceneTreeTimer
const UPLOAD_TIMEOUT_TIME := 15.0

func custom_sort_mp_entries(a: HBBackend.BackendLeaderboardEntry, b: HBBackend.BackendLeaderboardEntry):
	return b.game_info.result.score > b.game_info.result.score

func _process(delta: float) -> void:
	if current_timer:
		uploading_score_indicator_progress_bar.max_value = UPLOAD_TIMEOUT_TIME
		uploading_score_indicator_progress_bar.value = UPLOAD_TIMEOUT_TIME - current_timer.time_left
		uploading_score_indicator_progress_bar.step = 0.0

func _on_menu_enter(force_hard_transition = false, args = {}):
	super._on_menu_enter(force_hard_transition, args)
	copy_result_url_button.hide()
	results_tab.prev_result = null
	results_tab.experience_gain = null
	get_viewport().gui_release_focus()
	if args.has("assets"):
		current_assets = args.assets
	if args.has("game_info"):
		set_game_info(args.game_info)
	if args.has("hide_retry"):
		retry_button.hide()
	else:
		retry_button.show()
	if args.has("lobby"):
		mp_lobby = args.lobby
		mp_lobby.kicked.connect(self._on_kicked_from_lobby)
		buttons.select_button(return_button.get_index())
		# To be able to handle a song starting while we look at results
		show_song_results_mp.emit(mp_lobby)
	
func _on_kicked_from_lobby():
	change_to_menu("lobby_list", false, {"kicked": true})
	
func _return_to_lobby():
	change_to_menu("lobby", false, {"lobby": mp_lobby})
	
func _on_menu_exit(force_hard_transition=false):
	super._on_menu_exit(force_hard_transition)
	if mp_lobby:
		mp_lobby.disconnect("lobby_loading_start", Callable(self, "_on_lobby_loading_start"))
		mp_lobby = null
# called when authority sends a game start packet, sets up mp and starts loading
func _on_lobby_loading_start():
	var rhythm_game_multiplayer_scene = preload("res://rythm_game/rhythm_game_multiplayer.tscn").instantiate()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(rhythm_game_multiplayer_scene)
	get_tree().current_scene = rhythm_game_multiplayer_scene
	rhythm_game_multiplayer_scene.lobby = mp_lobby
	rhythm_game_multiplayer_scene.start_loading()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("gui_cancel") and not uploading_score_indicator.visible:
		_on_return_button_pressed()
	
func _ready():
	super._ready()
	set_process(false)
	error_window.connect("accept", upload_current_score)
	error_window.connect("cancel", Callable(buttons, "grab_focus"))
	
	ScoreHistory.connect("score_entered", Callable(self, "_on_score_entered"))
	ScoreHistory.connect("score_uploaded", Callable(self, "_on_score_uploaded"))
	ScoreHistory.connect("score_upload_failed", Callable(self, "_on_score_upload_failed"))
	var values = HBJudge.JUDGE_RATINGS.values()
	# HACK-y workaround for godot auto translation
	tabbed_container.add_tab(String("results").substr(0), tr("Results"), results_tab)
	tabbed_container.add_tab(String("stats").substr(0), tr("Accuracy"), stats_tab)
	tabbed_container.add_tab(String("graph").substr(0), tr("Graph"), chart_tab)
	return_button.connect("pressed", Callable(self, "_on_return_button_pressed"))
	retry_button.connect("pressed", Callable(self, "_on_retry_button_pressed"))
	copy_result_url_button.pressed.connect(self._on_copy_result_url_button_pressed)
	if PlatformService.service_provider.implements_ugc:
		var rate_buttons = [upvote_button, downvote_button, skip_button, no_opinion_button]
		for button in rate_buttons:
			button.connect("pressed", Callable(rating_popup, "hide"))
			button.connect("pressed", Callable(buttons, "grab_focus"))
		upvote_button.connect("pressed", Callable(self, "_on_vote_button_pressed").bind(HBUGCService.USER_ITEM_VOTE.UPVOTE))
		downvote_button.connect("pressed", Callable(self, "_on_vote_button_pressed").bind(HBUGCService.USER_ITEM_VOTE.DOWNVOTE))
		skip_button.connect("pressed", Callable(self, "_on_vote_button_pressed").bind(HBUGCService.USER_ITEM_VOTE.SKIP))
	
func upload_current_score():
	if game_info.is_leaderboard_legal():
		# add result to history
		var token := ScoreHistory.add_result_to_history(game_info)
		if not game_info.get_song().can_upload_scores():
			button_container.grab_focus()
			return
		token.score_uploaded.connect(_on_score_uploaded)
		token.score_upload_failed.connect(_on_score_upload_failed)
		get_viewport().gui_release_focus()
		uploading_score_indicator.show()
		current_timer = get_tree().create_timer(UPLOAD_TIMEOUT_TIME)
		set_process(true)
		current_timer.timeout.connect(
			func():
				token.backend_token.cancel_request()
				if uploading_score_indicator.visible:
					_on_score_upload_failed(tr("Score upload request timed out", &"Score upload request timeout error"))
		)
	
func _on_copy_result_url_button_pressed():
	const PROGRESS_THING := preload("res://autoloads/DownloadProgressThing.tscn")
	var progress_thing: HBDownloadProgressThing = PROGRESS_THING.instantiate()
	progress_thing.type = HBDownloadProgressThing.TYPE.SUCCESS
	progress_thing.text = tr("Score URL copied to clipboard!")
	progress_thing.life_timer = 2.0
	DownloadProgress.add_notification(progress_thing)
	
	var url := "https://ph.eirteam.moe/score/%d" % [score_web_id]
	DisplayServer.clipboard_set(url)

func _on_vote_button_pressed(vote):
	if PlatformService.service_provider.implements_ugc:
		var ugc = PlatformService.service_provider.ugc_provider as HBUGCService
		ugc.set_user_item_vote(current_song.ugc_id, vote)
	
func _on_retry_button_pressed():
	var new_scene = preload("res://menus/LoadingScreen.tscn")
	game_info.time = Time.get_unix_time_from_system()
	var scene = new_scene.instantiate()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	game_info.song_id = current_song.id
	game_info.difficulty = game_info.difficulty
	scene.load_song(game_info, false, current_assets)
	
func _on_return_button_pressed():
	if not mp_lobby:
		change_to_menu("song_list", false, {"song": game_info.song_id, "song_difficulty": game_info.difficulty})
	else:
		change_to_menu("lobby", false, {"lobby": mp_lobby})
func set_game_info(val: HBGameInfo):
	game_info = val
	uploading_score_indicator.hide()
	chart_tab.set_game_info(val)
	var result = game_info.result as HBResult
	
	stats_tab.result = result
	stats_tab.song = game_info.get_song()
	
	var previous_entry := ScoreHistory.get_data(game_info.song_id, game_info.difficulty)
	

	var score_percentage = 0
	if result.total_notes > 0:
		score_percentage = result.get_percentage()
	var highest_percentage = previous_entry.highest_percentage if previous_entry else 0.0
	var highest_score = previous_entry.highest_score if previous_entry else 0
	
	# We first set the things up without taking care of experience
	var has_previous_entry := previous_entry != null
	results_tab.result = result
	if previous_entry:
		results_tab.prev_result = previous_entry.highest_score_info.result
	else:
		results_tab.prev_result = null 

	if game_info.is_leaderboard_legal():
		# add result to history
		upload_current_score()
	
	if SongLoader.songs.has(game_info.song_id):
		var song = SongLoader.songs[game_info.song_id] as HBSong
		current_song = song
		var result_rating = result.get_result_rating()
		if not result.used_cheats:
			if current_song.comes_from_ugc():
				PlatformService.service_provider.unlock_achievement("ACHIEVEMENT_WORKSHOP")
				if result_rating == HBResult.RESULT_RATING.PERFECT:
					PlatformService.service_provider.unlock_achievement("ACHIEVEMENT_PERFECT_WORKSHOP")
			else:
				if current_song.get_fs_origin() == HBSong.SONG_FS_ORIGIN.BUILT_IN  and \
						result_rating == HBResult.RESULT_RATING.PERFECT and \
						game_info.difficulty.to_lower() == "extreme":
					PlatformService.service_provider.unlock_achievement("ACHIEVEMENT_PERFECT_BUILTIN")
			
			if result_rating != HBResult.RESULT_RATING.PERFECT:
				if result.note_ratings[HBJudge.JUDGE_RATINGS.SAFE] == 1:
					var result_clone = result.clone() as HBResult
					result_clone.note_ratings[HBJudge.JUDGE_RATINGS.SAFE] = 0
					if result_clone.get_result_rating() == HBResult.RESULT_RATING.PERFECT:
						PlatformService.service_provider.unlock_achievement("ACHIEVEMENT_1SAFE")
			else:
				if result.note_ratings[HBJudge.JUDGE_RATINGS.FINE] == 0:
					PlatformService.service_provider.unlock_achievement("ACHIEVEMENT_0F")
			
			if score_percentage > 0.6:
				if str(score_percentage*100.0).substr(0, 2) == "69":
					PlatformService.service_provider.unlock_achievement("ACHIEVEMENT_69")
		
			PlatformService.service_provider.save_achievements()
		
		title_label.set_song(song)
		title_label.difficulty = game_info.difficulty
		if not mp_lobby:
			emit_signal("select_song", song)
		
		if PlatformService.service_provider.implements_ugc:

			if song.comes_from_ugc():
				var ugc = PlatformService.service_provider.ugc_provider as HBUGCService
				if not ugc.has_user_item_vote(song.ugc_id):
					var vote = await ugc.get_user_item_vote(song.ugc_id)
					if vote == HBUGCService.USER_ITEM_VOTE.NOT_VOTED:
						# UGC songs can be rated at the end of the game
						rating_popup.popup_centered()
						rating_buttons_container.grab_focus()
		
	
func _on_score_uploaded(result: HBBackend.LeaderboardScoreUploadedResult):
	results_tab.prev_result = result.previous_record
	score_web_id = result.score_id
	results_tab.experience_gain = result.experience_gain_breakdown
	HBBackend.refresh_user_info()
	if score_web_id != -1:
		copy_result_url_button.show()
	button_container.grab_focus()
	uploading_score_indicator.hide()
func _on_score_upload_failed(reason):
	uploading_score_indicator.hide()
	error_window.text = tr("There was an issue uploading your score.\n\n%s\n\nWould you like to try uploading it again?" % [reason])
	error_window.popup_centered()
	
