extends Popup

onready var difficulty_container = get_node("Panel/MarginContainer/HBoxContainer")

func _ready():
	pass
func load_song(song: HBSong):
	for difficulty in difficulty_container.get_children():
		difficulty_container.remove_child(difficulty)
		difficulty.queue_free()
	for difficulty in song.charts:
		var button = HBHovereableButton.new()
		button.text = difficulty.capitalize()
		button.connect("pressed", self, "_select_difficulty", [song, difficulty])
		difficulty_container.add_child(button)
	# HACK: Wait one frame for the rect size to apply
	yield(get_tree(), "idle_frame")
	rect_size = $Panel/MarginContainer.rect_size
func _select_difficulty(song: HBSong, difficulty: String):
	var new_scene = preload("res://rythm_game/rhythm_game.tscn")
	var scene = new_scene.instance()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	scene.set_song(song, difficulty)
	hide()
	
func _gui_input(event):
	if event.is_action_pressed("ui_cancel"):
		hide()
		get_tree().set_input_as_handled()
