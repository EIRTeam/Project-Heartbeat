extends ScrollContainer

@onready var container = get_node("MarginContainer/HBoxContainer/VBoxContainer")
const DIFF = preload("res://tools/editor/ChartDiff.tscn")

func populate(song: HBSong, enabled: bool):
	for i in container.get_children():
		container.remove_child(i)
		i.queue_free()
	
	for chart_diff in song.charts:
		var diff = DIFF.instantiate()
		diff.size_flags_horizontal = SIZE_EXPAND_FILL
		container.add_child(diff)
		
		diff.label.text = chart_diff.capitalize()
		diff.set_meta("diff", chart_diff)
		diff.spinbox.step = 0.0
		diff.spinbox.value = song.charts[chart_diff].stars
		diff.spinbox.editable = enabled

func apply_to(song: HBSong):
	for child in container.get_children():
		var d = child.get_meta("diff")
		song.charts[d].stars = child.spinbox.value
