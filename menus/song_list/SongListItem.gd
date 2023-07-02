extends HBSongListItemBase

class_name HBSongListItem

var song : HBSong

var prev_focus
@onready var button = get_node("Control")
#onready var star_texture_rect = get_node("TextureRect")

@onready var stars_label = get_node("Control/TextureRect/StarsLabel")
@onready var song_title = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer2")
@onready var stars_texture_rect = get_node("Control/TextureRect")
var task: SongAssetLoadAsyncTask

@onready var arcade_texture_rect = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/TextureRect")
@onready var console_texture_rect = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/TextureRect2")
@onready var download_texture_rect = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/DownloadTextureRect")
#HBNoteData.get_note_graphic(data.note_type, "note")

func _ready():
	super._ready()
	arcade_texture_rect.hide()
	console_texture_rect.hide()

func _on_song_cached():
	get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/DownloadTextureRect").visible = not song.is_cached() and song.youtube_url

func set_song(value: HBSong):
	if song:
		song.disconnect("song_cached", Callable(self, "_on_song_cached"))
	song = value
	song.connect("song_cached", Callable(self, "_on_song_cached"))
	get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/DownloadTextureRect").visible = not song.is_cached() and song.youtube_url
	get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer2").song = song
	var max_stars = value.get_max_score()
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
	get_node("Control/TextureRect/StarsLabel").text = stars_string
#	if ScoreHistory.has_result(value.id, difficulty):
#		var result := ScoreHistory.get_result(value.id, difficulty) as HBResult
#		var pass_percentage = result.get_percentage()
#		var score_text = "%s - %.2f" % [HBUtils.find_key(HBResult.RESULT_RATING, result.get_result_rating()), pass_percentage * 100.0]
#		score_text += " %"
#		score_label.text = score_text
#	else:
#		score_label.hide()

#	stars_texture_rect.rect_position = Vector2(-88, -25)
#	star_texture_rect.rect_position = Vector2(-(star_texture_rect.rect_size.x/2.0), (rect_size.y / 2.0) - ((star_texture_rect.rect_size.y) / 2.0))
	
#	var new_scene = preload("res://rythm_game/rhythm_game_controller.tscn")
#	var scene = new_scene.instance()
#	get_tree().current_scene.queue_free()
#	get_tree().root.add_child(scene)
#	get_tree().current_scene = scene
#	scene.set_song(song)

# Called by UniversalScrollList when the item becomes visible

var note_usage_shown = false

func _show_note_usage():
	var global_note_type_usage = []
	for difficulty in song.charts:
		for type in song.get_chart_note_usage(difficulty):
			if not type in global_note_type_usage:
				global_note_type_usage.append(type)
			if global_note_type_usage.size() >= HBChart.ChartNoteUsage.size():
				break
	if HBChart.ChartNoteUsage.ARCADE in global_note_type_usage:
		arcade_texture_rect.texture = ResourcePackLoader.get_graphic("slide_right_note.png")
		arcade_texture_rect.show()
	if HBChart.ChartNoteUsage.CONSOLE in global_note_type_usage:
		console_texture_rect.texture = ResourcePackLoader.get_graphic("heart_note.png")
		console_texture_rect.show()
	note_usage_shown = true
func _on_note_usage_loaded(assets):
	_show_note_usage()

func _become_visible():
	if note_usage_shown:
		return
	if not task:
		if song.is_chart_note_usage_known_all():
			_show_note_usage()
		else:
			task = SongAssetLoadAsyncTask.new(["note_usage"], song)
			task.connect("assets_loaded", Callable(self, "_on_note_usage_loaded"))
			AsyncTaskQueueLight.queue_task(task)
		
