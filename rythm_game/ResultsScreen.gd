extends HBMenu

var result : HBResult setget set_result

onready var rating_results_container = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel/RatingResultsContainer")
onready var percentage_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer2/PercentageLabel")
onready var artist_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer/ArtistLabel")
onready var title_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer/TitleLabel")
onready var combo_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel2/MarginContainer/MarginContainer/VBoxContainer/HBoxContainer/ComboLabel")
onready var score_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel2/MarginContainer/MarginContainer/VBoxContainer/HBoxContainer2/ScoreLabel")
onready var total_notes_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel2/MarginContainer/MarginContainer/VBoxContainer/HBoxContainer3/TotalNotesLabel")
onready var result_rating_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer2/ResultRatingLabel")
onready var buttons = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel3/MarginContainer/VBoxContainer")
onready var return_button = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel3/MarginContainer/VBoxContainer/HBHovereableButton2")
onready var heart_power_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel2/MarginContainer/MarginContainer/VBoxContainer/HBoxContainer4/HeartPowerLabel")
onready var button_panel = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel3")
onready var button_container = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel3/MarginContainer/VBoxContainer")
onready var retry_button = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel3/MarginContainer/VBoxContainer/HBHovereableButton")
var rating_results_scenes = {}
const ResultRating = preload("res://rythm_game/results_screen/ResultRating.tscn")

const BASE_BUTTON_PANEL_HEIGHT = 106
const BASE_HEIGHT = 720.0

func _on_menu_enter(force_hard_transition = false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	if args.has("results"):
		set_result(args.results)
	buttons.grab_focus()

func _on_resized():
	# We have to wait a frame for the resize to happen...
	# seriously wtf
	yield(get_tree(), "idle_frame")
	var inv = 0.3 / (rect_size.y / BASE_HEIGHT)
	button_panel.size_flags_stretch_ratio = inv

func _ready():
	connect("resized", self, "_on_resized")
	_on_resized()
	var values = HBJudge.JUDGE_RATINGS.values()
	for i in range(values.size()-1, -1, -1):
		var rating = values[i]
		var rating_scene = ResultRating.instance()
		rating_scene.odd = i % 2 == 0
		print(rating_scene.odd)
		rating_results_container.add_child(rating_scene)
		rating_results_scenes[rating] = rating_scene
		rating_scene.rating = rating
	return_button.connect("pressed", self, "_on_return_button_pressed")
	retry_button.connect("pressed", self, "_on_retry_button_pressed")
	
func _on_retry_button_pressed():
	var new_scene = preload("res://rythm_game/rhythm_game.tscn")
	var scene = new_scene.instance()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	scene.set_song(SongLoader.songs[result.song_id], result.difficulty)
	
func _on_return_button_pressed():
	change_to_menu("song_list", false, {"song": result.song_id, "song_difficulty": result.difficulty})

func set_result(val: HBResult):
	result = val
	for rating in rating_results_scenes:
		var rating_scene = rating_results_scenes[rating]
		rating_scene.percentage = 0
		if float(result.total_notes) > 0:
			rating_scene.percentage = result.note_ratings[rating] / float(result.total_notes)
		rating_scene.total_notes = result.note_ratings[rating]
	var score_percentage = 0
	if result.total_notes > 0:
		score_percentage = val.get_percentage()
	percentage_label.text = "%.2f" % (score_percentage * 100.0)
	percentage_label.text += " %"
	heart_power_label.text = str(val.heart_power_bonus)
	if SongLoader.songs.has(result.song_id):
		var song = SongLoader.songs[result.song_id] as HBSong
		title_label.text = song.title
		if song.artist_alias != "":
			artist_label.text = song.artist_alias.to_upper()
		else:
			artist_label.text = song.artist.to_upper()
	combo_label.text = str(result.max_combo)
	score_label.text = str(result.score)
	total_notes_label.text = str(result.total_notes)

	result_rating_label.text = HBUtils.find_key(HBResult.RESULT_RATING, result.get_result_rating())

	# add result to history
	if ScoreHistory.has_result(result.song_id, result.difficulty):
		var existing_result : HBResult = ScoreHistory.get_result(result.song_id, result.difficulty)
		if existing_result.score < result.score:
			ScoreHistory.add_result_to_history(result)
	else:
			ScoreHistory.add_result_to_history(result)
