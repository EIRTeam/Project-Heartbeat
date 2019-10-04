extends WindowDialog
onready var tree : Tree = get_node("MarginContainer/VBoxContainer/Tree")

signal chart_selected(song_id, difficulty)

func _ready():
	popullate_tree()
	
func popullate_tree():
	tree.clear()
	tree.create_item()
	for song_id in SongLoader.songs:
		var song = SongLoader.songs[song_id]
		var item := tree.create_item()
		item.set_text(0, song.title)
		item.set_selectable(0, false)
		for chart in song.charts:
			var chart_item := tree.create_item(item)
			chart_item.set_text(0, chart.capitalize())
			chart_item.set_meta("song_id", song.id)
			chart_item.set_meta("difficulty", chart)


func _on_SelectButton_pressed():
	if tree.get_selected():
		emit_signal("chart_selected", tree.get_selected().get_meta("song_id"), tree.get_selected().get_meta("difficulty"))
		hide()
