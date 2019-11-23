extends Control

var result : HBResult setget set_result

onready var rating_results_container = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel2/MarginContainer/VBoxContainer/RatingResultsContainer")
onready var percentage_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer2/PercentageLabel")
onready var artist_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer/ArtistLabel")
onready var title_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/HBoxContainer/TitleLabel")
onready var combo_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel2/MarginContainer/VBoxContainer/ExtraDataPanel/MarginContainer/VBoxContainer/HBoxContainer/ComboLabel")
onready var score_label = get_node("MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/VBoxContainer2/Panel2/MarginContainer/VBoxContainer/ExtraDataPanel/MarginContainer/VBoxContainer/HBoxContainer2/ScoreLabel")
var rating_results_scenes = {}
const ResultRating = preload("res://rythm_game/results_screen/ResultRating.tscn")

func _ready():
	var file = File.new()
	file.open("user://testresult.json", File.READ)
	for rating in HBJudge.JUDGE_RATINGS.values():
		var rating_scene = ResultRating.instance()
		rating_results_container.add_child(rating_scene)
		rating_results_scenes[rating] = rating_scene
		rating_scene.rating = rating
		
	set_result(HBSerializable.deserialize(JSON.parse(file.get_as_text()).result))

func set_result(val):
	result = val
	for rating in rating_results_scenes:
		var rating_scene = rating_results_scenes[rating]
		rating_scene.percentage = result.note_ratings[str(rating)] / float(result.total_notes)
		rating_scene.total_notes = result.note_ratings[str(rating)]
	var cool = float(result.note_ratings[str(HBJudge.JUDGE_RATINGS.COOL)])
	var fine = float(result.note_ratings[str(HBJudge.JUDGE_RATINGS.FINE)])
	percentage_label.text = "%.2f" % (((cool + fine) / float(result.total_notes)) * 100.0)
	percentage_label.text += " %"
	if SongLoader.songs.has(result.song_id):
		var song = SongLoader.songs[result.song_id] as HBSong
		title_label.text = song.title
		if song.artist_alias != "":
			artist_label.text = song.artist_alias.to_upper()
		else:
			artist_label.text = song.artist.to_upper()
	combo_label.text = str(result.max_combo)
	score_label.text = str(result.score)
