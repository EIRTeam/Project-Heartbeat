extends Control

class_name HBSongListItem

var song : HBSong


var hover_style = preload("res://styles/SongListItemHover.tres")
var normal_style = preload("res://styles/SongListItemNormal.tres")

var target_opacity = 1.0

const LERP_SPEED = 3.0

signal pressed

var prev_focus
onready var stars_label = get_node("Control/TextureRect/StarsLabel")
onready var song_title = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2")
onready var stars_texture_rect = get_node("Control/TextureRect")
onready var button = get_node("Control")
#onready var star_texture_rect = get_node("TextureRect")
signal song_selected(song)

func set_song(value: HBSong):
	song = value

	song_title.song = song
	var max_stars = 0
	for chart in value.charts:
		if value.charts[chart].has("stars"):
			var stars = value.charts[chart].stars
			if stars > max_stars:
				max_stars = stars
	var stars_string = "-"
	if max_stars != 0:
		if fmod(max_stars, floor(max_stars)) != 0:
			stars_string = "%.1f" % [max_stars]
		else:
			stars_string = "%d" % [max_stars]
	stars_label.text = stars_string
		
#	if ScoreHistory.has_result(value.id, difficulty):
#		var result := ScoreHistory.get_result(value.id, difficulty) as HBResult
#		var pass_percentage = result.get_percentage()
#		var score_text = "%s - %.2f" % [HBUtils.find_key(HBResult.RESULT_RATING, result.get_result_rating()), pass_percentage * 100.0]
#		score_text += " %"
#		score_label.text = score_text
#	else:
#		score_label.hide()

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

func _gui_input(event):
	if event.is_action_pressed("gui_accept") and not event.is_echo():
		emit_signal("song_selected", song)
#	var new_scene = preload("res://rythm_game/rhythm_game_controller.tscn")
#	var scene = new_scene.instance()
#	get_tree().current_scene.queue_free()
#	get_tree().root.add_child(scene)
#	get_tree().current_scene = scene
#	scene.set_song(song)

