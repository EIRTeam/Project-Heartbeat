extends Control
class_name HBRhythmGameUIBase
var disable_score_processing = false
func get_notes_node() -> Node2D:
	return Node2D.new()
func _on_reset():
	pass
func _on_chart_set(chart: HBChart):
	pass
func _on_song_set(song: HBSong, difficulty: String, assets = null, modifiers = []):
	pass
func get_lyrics_view():
	pass
