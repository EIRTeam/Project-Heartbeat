extends BaseButton

var song : HBSong


var hover_style = preload("res://styles/SongListItemHover.tres")
var normal_style = preload("res://styles/SongListItemNormal.tres")

var target_opacity = 1.0

const LERP_SPEED = 3.0

var prev_focus
onready var score_label = get_node("MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/ScoreLabel")
onready var stars_label = get_node("MarginContainer/HBoxContainer/TextureRect/StarsLabel")
onready var song_title = get_node("MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2")
signal song_selected(song)

func set_song(value: HBSong, difficulty: String):
	song = value

	song_title.song = song
	if value.charts[difficulty].has("stars"):
		stars_label.text = str(int(value.charts[difficulty].stars))
	else:
		stars_label.text = "-"
		
	if ScoreHistory.has_result(value.id, difficulty):
		var result := ScoreHistory.get_result(value.id, difficulty) as HBResult
		var pass_percentage = result.get_percentage()
		var score_text = "%s - %.2f" % [HBUtils.find_key(HBResult.RESULT_RATING, result.get_result_rating()), pass_percentage * 100.0]
		score_text += " %"
		score_label.text = score_text
	else:
		score_label.hide()
func hover():
	add_stylebox_override("normal", hover_style)

func stop_hover():
	add_stylebox_override("normal", normal_style)
	
func _process(delta):
	modulate.a = lerp(modulate.a, target_opacity, LERP_SPEED*delta)

func _on_pressed():
	emit_signal("song_selected", song)
#	var new_scene = preload("res://rythm_game/rhythm_game_controller.tscn")
#	var scene = new_scene.instance()
#	get_tree().current_scene.queue_free()
#	get_tree().root.add_child(scene)
#	get_tree().current_scene = scene
#	scene.set_song(song)

