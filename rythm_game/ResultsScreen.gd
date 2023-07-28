extends HBMenu

var game_info : HBGameInfo: set = set_game_info

@onready var percentage_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer2/PercentageLabel")
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
@onready var share_on_twitter_button = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel3/MarginContainer/VBoxContainer/ShareOnTwitterButton")
@onready var hi_score_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer2/Label")
@onready var result_rating_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer2/ResultRatingLabel")
@onready var error_window = get_node("HBConfirmationWindow")
var rating_results_scenes = {}
const ResultRating = preload("res://rythm_game/results_screen/ResultRating.tscn")
const BASE_HEIGHT = 720.0

signal show_song_results(song_id, difficulty)
signal show_song_results_mp(entries)
signal select_song(song)

var mp_lobby: HBLobby
var mp_entries = {}
var current_song: HBSong
var current_assets

@onready var tabbed_container = get_node("MarginContainer/VBoxContainer/VBoxContainer2/TabbedContainer")
@onready var results_tab = preload("res://rythm_game/results_screen/ResultsScreenResultTab.tscn").instantiate()
@onready var chart_tab = preload("res://rythm_game/results_screen/ResultsScreenGraphTab.tscn").instantiate()

func custom_sort_mp_entries(a: HBBackend.BackendLeaderboardEntry, b: HBBackend.BackendLeaderboardEntry):
	return b.game_info.result.score > b.game_info.result.score
func _on_menu_enter(force_hard_transition = false, args = {}):
	super._on_menu_enter(force_hard_transition, args)
	buttons.grab_focus()
	if args.has("assets"):
		current_assets = args.assets
	if args.has("game_info"):
		set_game_info(args.game_info)
	if args.has("hide_retry"):
		retry_button.hide()
	else:
		retry_button.show()
	if args.has("mp_entries"):
		mp_entries = args.mp_entries
		var lb_entries = []
		for member in mp_entries:
			var entry = mp_entries[member] as HBResult
			var lb_entry = HBBackend.BackendLeaderboardEntry.new(member, 0, HBGameInfo.new())
			lb_entry.game_info.result.score = entry.get_capped_score()
			lb_entry = entry.get_percentage()
			lb_entries.append(lb_entry)
		lb_entries.sort_custom(Callable(self, "custom_sort_mp_entries"))
		for entry_i in lb_entries.size():
			lb_entries[entry_i].rank = entry_i+1
		emit_signal("show_song_results_mp", lb_entries)
	if args.has("lobby"):
		mp_lobby = args.lobby
		buttons.select_button(return_button.get_index())
		# To be able to handle a song starting while we look at results		
		mp_lobby.connect("lobby_loading_start", Callable(self, "_on_lobby_loading_start"))
	
	
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
	
func _on_resized():
	# We have to wait a frame for the resize to happen...
	# seriously wtf
	if (size.y / BASE_HEIGHT) > 0:
		var inv = 0.1 / (size.y / BASE_HEIGHT)
		button_panel.size_flags_stretch_ratio = inv

func _ready():
	super._ready()
	error_window.connect("accept", Callable(buttons, "grab_focus"))
	
	connect("resized", Callable(self, "_on_resized"))
	ScoreHistory.connect("score_entered", Callable(self, "_on_score_entered"))
	ScoreHistory.connect("score_uploaded", Callable(self, "_on_score_uploaded"))
	ScoreHistory.connect("score_upload_failed", Callable(self, "_on_score_upload_failed"))
	_on_resized()
	var values = HBJudge.JUDGE_RATINGS.values()
	tabbed_container.add_tab("results", tr("Results"), results_tab)
	tabbed_container.add_tab("graph", tr("Graph"), chart_tab)
	
	for i in range(values.size()-1, -1, -1):
		var rating = values[i]
		var rating_scene = ResultRating.instantiate()
		rating_scene.odd = i % 2 == 0
		results_tab.rating_results_container.add_child(rating_scene)
		rating_results_scenes[rating] = rating_scene
		rating_scene.rating = rating
	return_button.connect("pressed", Callable(self, "_on_return_button_pressed"))
	retry_button.connect("pressed", Callable(self, "_on_retry_button_pressed"))
	share_on_twitter_button.connect("pressed", Callable(self, "_on_share_on_twitter_pressed"))
	if PlatformService.service_provider.implements_ugc:
		var rate_buttons = [upvote_button, downvote_button, skip_button, no_opinion_button]
		for button in rate_buttons:
			button.connect("pressed", Callable(rating_popup, "hide"))
			button.connect("pressed", Callable(buttons, "grab_focus"))
		upvote_button.connect("pressed", Callable(self, "_on_vote_button_pressed").bind(HBUGCService.USER_ITEM_VOTE.UPVOTE))
		downvote_button.connect("pressed", Callable(self, "_on_vote_button_pressed").bind(HBUGCService.USER_ITEM_VOTE.DOWNVOTE))
		skip_button.connect("pressed", Callable(self, "_on_vote_button_pressed").bind(HBUGCService.USER_ITEM_VOTE.SKIP))
func _on_share_on_twitter_pressed():
	var song = SongLoader.songs[game_info.song_id] as HBSong
	var result_pretty = HBUtils.thousands_sep(game_info.result.score)
	var tweet_message = "I just obtained %s (%.2f %%25) points in %s in @PHeartbeatGame" % [result_pretty, game_info.result.get_percentage() * 100.0, song.get_visible_title()]
	OS.shell_open("https://twitter.com/intent/tweet?text=%s&hashtags=ProjectHeartbeat" % [tweet_message])

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
	chart_tab.set_game_info(val)
	results_tab.experience_container.hide()
	results_tab.level_up_container.hide()
	hi_score_label.hide()
	var result = game_info.result as HBResult
	
	var previous_entry = ScoreHistory.get_data(game_info.song_id, game_info.difficulty)
	
	for rating in rating_results_scenes:
		var rating_scene = rating_results_scenes[rating]
		rating_scene.percentage = 0
		if float(result.total_notes) > 0:
			var results = result.note_ratings[rating]
			if rating == HBJudge.JUDGE_RATINGS.WORST:
				# Add wrong notes
				for r in result.wrong_note_ratings.values():
					results += r
			rating_scene.percentage = results  / float(result.total_notes)
			rating_scene.total_notes = results
	var score_percentage = 0
	if result.total_notes > 0:
		score_percentage = result.get_percentage()
	var percentage_text = "%.2f" % (score_percentage * 100.0)
	percentage_text += " %"
	percentage_label.text = percentage_text
	
	results_tab.combo_label.text = str(result.max_combo)
	results_tab.total_notes_label.text = str(result.total_notes)
	
	var highest_percentage = previous_entry.highest_percentage if previous_entry else 0.0
	var highest_score = previous_entry.highest_score if previous_entry else 0
	
	results_tab.current_percent_label.text = percentage_text
	results_tab.current_score_label.text = str(result.score)
	results_tab.hiscore_percent_label.text = ("%.2f" % (highest_percentage * 100.0)) + " %"
	results_tab.hiscore_score_label.text = str(highest_score)
	
	if score_percentage > highest_percentage and game_info.is_leaderboard_legal():
		results_tab.current_percent_label.text = "[word_rainbow]" + results_tab.current_percent_label.text + "[/word_rainbow]"
	if result.score > highest_score and game_info.is_leaderboard_legal():
		results_tab.current_score_label.text = "[word_rainbow]" + results_tab.current_score_label.text + "[/word_rainbow]"

	result_rating_label.text = HBUtils.find_key(HBResult.RESULT_RATING, result.get_result_rating())
	if game_info.is_leaderboard_legal():
		# add result to history
		ScoreHistory.add_result_to_history(game_info)
	else:
		_on_score_entered(game_info.song_id, game_info.difficulty)
	
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
					var vote = await ugc.get_user_item_vote(song.ugc_id).completed
					if vote == HBUGCService.USER_ITEM_VOTE.NOT_VOTED:
						# UGC songs can be rated at the end of the game
						rating_popup.popup_centered()
						rating_buttons_container.grab_focus()
		
	
func _on_score_uploaded(result):
	if "experience_change" in result:
		if "level_change" in result and result.level_change > 0:
			results_tab.level_up_container.show()
		else:
			results_tab.experience_container.show()
			results_tab.experience_label.text = "Gained\n%dxp!" % [result.experience_change]
	
	if "beat_previous_record" in result and result.beat_previous_record:
		hi_score_label.show()
	else:
		hi_score_label.hide()
	HBBackend.refresh_user_info()
	
func _on_score_upload_failed(reason):
	error_window.text = tr("There was an issue uploading your score:\n%s" % [reason])
	error_window.popup_centered()
	
func _on_score_entered(song, difficulty):
	if not mp_lobby:
		emit_signal("show_song_results", song, difficulty, game_info.modifiers.size() != 0)
