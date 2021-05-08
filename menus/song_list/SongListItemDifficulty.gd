extends HBSongListItemBase

class_name HBSongListItemDifficulty

var difficulty: String

onready var score_label = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/ScoreLabel")
onready var difficulty_label = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/DifficultyLabel")
onready var stars_container = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer")
onready var stars_texture_rect = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/StarTextureRect")
onready var stars_label = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/StarsLabel")
onready var song_title = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2")
onready var arcade_texture = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/ArcadeTexture")
onready var console_texture = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer/HBoxContainer/ConsoleTexture")
var song: HBSong
#onready var star_texture_rect = get_node("TextureRect")

func _ready():
	arcade_texture.hide()
	console_texture.hide()

func set_song_difficulty(value: HBSong, _difficulty: String):
	song = value
	song_title.song = song
	difficulty = _difficulty
	if fmod(song.charts[difficulty].stars, floor(song.charts[difficulty].stars)) != 0:
		stars_label.text = "x%.1f " % [song.charts[difficulty].stars]
	else:
		stars_label.text = "x%d " % [song.charts[difficulty].stars]
	difficulty_label.text = " " + difficulty.to_upper() + " "
	if ScoreHistory.has_result(value.id, difficulty):
		var result := ScoreHistory.get_result(value.id, difficulty) as HBHistoryEntry
		var pass_percentage = result.highest_percentage
		var thousands_sep_score = HBUtils.thousands_sep(result.highest_score)
		var score_text = "%s - %.2f %% - %s" % [HBUtils.find_key(HBResult.RESULT_RATING, result.highest_rating), pass_percentage * 100.0, thousands_sep_score]
		score_label.text = score_text
	else:
		score_label.hide()
		
func show_note_usage():
	var usage = song.get_chart_note_usage(difficulty)
	if HBChart.ChartNoteUsage.ARCADE in usage:
		arcade_texture.texture = HBNoteData.get_note_graphic(HBNoteData.NOTE_TYPE.SLIDE_RIGHT, "note")
		arcade_texture.show()
	if HBChart.ChartNoteUsage.CONSOLE in usage:
		console_texture.texture = HBNoteData.get_note_graphic(HBNoteData.NOTE_TYPE.HEART, "note")
		console_texture.show()
		
func _on_note_usage_loaded(assets):
	show_note_usage()
#	stars_texture_rect.rect_position = Vector2(-88, -25)
#	star_texture_rect.rect_position = Vector2(-(star_texture_rect.rect_size.x/2.0), (rect_size.y / 2.0) - ((star_texture_rect.rect_size.y) / 2.0))

#func set_difficulty_types_map(difficulty_types_map: )
