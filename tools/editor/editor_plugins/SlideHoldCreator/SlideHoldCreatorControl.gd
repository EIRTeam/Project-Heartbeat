extends VBoxContainer

signal create_notes(notes_per_beat, beats)

onready var resolution_spinbox = get_node("HBoxContainer/ResolutionSpinBox")
onready var beats_spinbox = get_node("BeatsSpinBox")

func _on_CreateButton_pressed():
	emit_signal("create_notes", resolution_spinbox.value, beats_spinbox.value)
