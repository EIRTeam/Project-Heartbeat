extends HBRhythmGameUIBase

onready var rating_label: Label = get_node("RatingLabel")
onready var game_layer_node = get_node("GameLayer")
onready var top_ui = get_node("Control/HBoxContainer")
onready var hold_indicator = get_node("UnderNotesUI/Control/HoldIndicator")
onready var slide_hold_score_text = get_node("AboveNotesUI/Control/SlideHoldScoreText")
onready var under_notes_node = get_node("UnderNotesUI")

var drawing_layer_nodes = {}

const LOG_NAME = "HeartbeatRhythmGameUI"

var start_time = 0.0
var end_time = 0.0

var game setget set_game

func set_game(new_game):
	game = new_game
	slide_hold_score_text._game = game
	game.connect("time_changed", self, "_on_game_time_changed")


func _ready():
	rating_label.hide()
	connect("resized", self, "_on_size_changed")
	call_deferred("_on_size_changed")
	
	add_drawing_layer("Laser")
	add_drawing_layer("Trails")
	add_drawing_layer("StarParticles")
	add_drawing_layer("HitParticles")
	add_drawing_layer("AppearParticles")
	add_drawing_layer("SlideChainPieces")
	add_drawing_layer("Notes")
	
	disable_score_processing = true


func add_drawing_layer(layer_name: String):
	var layer_node = Node2D.new()
	layer_node.name = "LAYER_" + layer_name
	game_layer_node.add_child(layer_node)
	drawing_layer_nodes[layer_name] = layer_node

func get_drawing_layer_node(layer_name: String) -> Node2D:
	return drawing_layer_nodes[layer_name]

func get_notes_node() -> Node2D:
	return get_drawing_layer_node("Notes")


func _on_note_judged(judgement_info):
	rating_label.show_rating()
	rating_label.get_node("AnimationPlayer").play("rating_appear")
	if not judgement_info.wrong:
		rating_label.add_color_override("font_color", Color(HBJudge.RATING_TO_COLOR[judgement_info.judgement]))
		rating_label.add_color_override("font_outline_modulate", HBJudge.RATING_TO_COLOR[judgement_info.judgement])
		rating_label.text = HBJudge.JUDGE_RATINGS.keys()[judgement_info.judgement]
	else:
		rating_label.add_color_override("font_color", Color(game.WRONG_COLOR))
		rating_label.add_color_override("font_outline_modulate", game.WRONG_COLOR)
		rating_label.text = HBJudge.RATING_TO_WRONG_TEXT_MAP[judgement_info.judgement]
	if game.current_combo > 1:
		rating_label.text += " " + str(game.current_combo)
	rating_label.rect_position = game.remap_coords(judgement_info.avg_pos) - rating_label.rect_size / 2
	if rating_label.rect_global_position.y > top_ui.rect_global_position.y + top_ui.rect_size.y:
		rating_label.rect_position.y -= 64
	else:
		rating_label.rect_position.y += 64
	if not game.previewing:
		rating_label.show()
	else:
		rating_label.hide()


func _on_size_changed():
	if game:
		$UnderNotesUI/Control.set_deferred("rect_size", game.size)
		$AboveNotesUI/Control.set_deferred("rect_size", game.size)
		$Lyrics/Control.set_deferred("rect_size", game.size)


func _on_reset():
	rating_label.hide()

func _on_hold_released_early():
	# When you release a hold it disappears instantly
	hold_indicator.disappear()

func _on_max_hold():
	hold_indicator.show_max_combo(game.MAX_HOLD)

func _on_hold_score_changed(new_score: float):
	hold_indicator.current_score = new_score

func _on_show_slide_hold_score(point: Vector2, score: float, show_max: bool):
	slide_hold_score_text.show_at_point(point, score, show_max)

func _on_hold_started(holds):
	hold_indicator.current_holds = holds
	hold_indicator.appear()


func _input(event):
	if event.is_action_pressed("hide_ui") and event.control and not event.shift and not game.editing:
		_on_toggle_ui()
		get_tree().set_input_as_handled()


func _on_toggle_ui():
	$UnderNotesUI/Control.visible = !$UnderNotesUI/Control.visible
	$AboveNotesUI/Control.visible = !$UnderNotesUI/Control.visible
	$Control.visible = !$Control.visible

func is_ui_visible():
	return $Control.visible
