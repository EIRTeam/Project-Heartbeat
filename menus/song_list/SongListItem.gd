extends HBSongListItemBase

class_name HBSongListItem

var song : HBSong

var prev_focus
onready var button = get_node("Control")
#onready var star_texture_rect = get_node("TextureRect")
signal song_selected(song)

onready var stars_label = get_node("Control/TextureRect/StarsLabel")
onready var song_title = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer2")
onready var stars_texture_rect = get_node("Control/TextureRect")
var task: SongAssetLoadAsyncTask
var note_usage_map

onready var arcade_texture_rect = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/TextureRect")
onready var console_texture_rect = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/TextureRect2")
#HBNoteData.get_note_graphic(data.note_type, "note")

func _ready():
	arcade_texture_rect.hide()
	console_texture_rect.hide()

func set_song(value: HBSong):
	song = value

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

func _set_note_usage_map(map):
	note_usage_map = map
	var global_note_type_usage = []
	for difficulty in note_usage_map:
		for type in note_usage_map[difficulty]:
			if not type in global_note_type_usage:
				global_note_type_usage.append(type)
			if global_note_type_usage.size() >= HBSong.SongChartNoteUsage.size():
				break
	if HBSong.SongChartNoteUsage.ARCADE in global_note_type_usage:
		arcade_texture_rect.texture = HBNoteData.get_note_graphic(HBNoteData.NOTE_TYPE.SLIDE_RIGHT, "note")
		arcade_texture_rect.show()
	if HBSong.SongChartNoteUsage.CONSOLE in global_note_type_usage:
		console_texture_rect.texture = HBNoteData.get_note_graphic(HBNoteData.NOTE_TYPE.HEART, "note")
		console_texture_rect.show()
func _on_note_usage_loaded(assets):
	if "note_usage" in assets:
		_set_note_usage_map(assets.note_usage)

func _become_visible():
	if not task:
		if not song._note_usage_cache.empty():
			_set_note_usage_map(song._note_usage_cache)
		else:
			task = SongAssetLoadAsyncTask.new(["note_usage"], song)
			task.connect("assets_loaded", self, "_on_note_usage_loaded")
			AsyncTaskQueueLight.queue_task(task)
		
