extends ScrollContainer

onready var container = get_node("MarginContainer/HBoxContainer/VBoxContainer")
const DIFF = preload("res://tools/editor/ChartDiff.tscn")
func populate(song: HBSong):
	for i in container.get_children():
		container.remove_child(i)
		i.queue_free()
	for chart_diff in song.charts:
		var diff = DIFF.instance()
		container.add_child(diff)
		diff.label.text = chart_diff.capitalize()
		diff.spinbox.step = 0.0
		diff.spinbox.value = song.charts[chart_diff].stars
func apply_to(song: HBSong):
	for child in container.get_children():
		song.charts[child.label.text.to_lower()].stars = child.spinbox.value
