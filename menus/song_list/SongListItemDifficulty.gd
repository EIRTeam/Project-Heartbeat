extends Control

class_name HBSongListItemDifficulty

var song : HBSong
var difficulty: String
var hover_style = preload("res://styles/SongListItemHover.tres")
var normal_style = preload("res://styles/SongListItemNormal.tres")

var target_opacity = 1.0

const LERP_SPEED = 3.0

signal pressed

var prev_focus
onready var song_title = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2")
onready var stars_texture_rect = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/StarTextureRect")
onready var stars_label = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/StarsLabel")
onready var score_label = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/ScoreLabel")
onready var button = get_node("Control")
onready var difficulty_label = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/DifficultyLabel")
onready var stars_container = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer")
#onready var star_texture_rect = get_node("TextureRect")

func set_song(value: HBSong, difficulty: String):
	song = value
	song_title.song = song
	var max_stars = 0
	if fmod(song.charts[difficulty].stars, floor(song.charts[difficulty].stars)) != 0:
		stars_label.text = "x%.1f " % [song.charts[difficulty].stars]
	else:
		stars_label.text = "x%d " % [song.charts[difficulty].stars]
	difficulty_label.text = " " + difficulty.to_upper() + " "
	self.difficulty = difficulty
	if ScoreHistory.has_result(value.id, difficulty):
		var result := ScoreHistory.get_result(value.id, difficulty) as HBResult
		var pass_percentage = result.get_percentage()
		var score_text = "%s - %.2f" % [HBUtils.find_key(HBResult.RESULT_RATING, result.get_result_rating()), pass_percentage * 100.0]
		score_text += " %"
		score_label.text = score_text
	else:
		score_label.hide()

func _on_resize():
	pass
#	stars_texture_rect.rect_position = Vector2(-88, -25)
#	star_texture_rect.rect_position = Vector2(-(star_texture_rect.rect_size.x/2.0), (rect_size.y / 2.0) - ((star_texture_rect.rect_size.y) / 2.0))

func _ready():
	connect("resized", self, "_on_resize")
	_on_resize()

func hover():
	button.add_stylebox_override("normal", hover_style)

func stop_hover():
	button.add_stylebox_override("normal", normal_style)
	
func _process(delta):
	modulate.a = lerp(modulate.a, target_opacity, LERP_SPEED*delta)
#	var new_scene = preload("res://rythm_game/rhythm_game_controller.tscn")
#	var scene = new_scene.instance()
#	get_tree().current_scene.queue_free()
#	get_tree().root.add_child(scene)
#	get_tree().current_scene = scene
#	scene.set_song(song)

