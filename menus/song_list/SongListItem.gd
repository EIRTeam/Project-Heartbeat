extends BaseButton

var song : HBSong


var hover_style = preload("res://styles/SongListItemHover.tres")
var normal_style = preload("res://styles/SongListItemNormal.tres")

var target_opacity = 1.0

const LERP_SPEED = 3.0

var prev_focus
onready var title_label = get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/TitleLabel")
onready var author_label = get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/AuthorLabel")
onready var score_label = get_node("MarginContainer/HBoxContainer/VBoxContainer/ScoreLabel")

onready var stars_label = get_node("MarginContainer/HBoxContainer/TextureRect/StarsLabel")
signal song_selected(song)

func set_song(value: HBSong, difficulty: String):
	song = value
	title_label.text = song.title
	if song.artist_alias != "":
		author_label.text = song.artist_alias
	else:
		author_label.text = song.artist
		
	if value.charts[difficulty].has("stars"):
		stars_label.text = str(int(value.charts[difficulty].stars))
	else:
		stars_label.text = "-"
		
	if ScoreHistory.has_result(value.id, difficulty):
		var result := ScoreHistory.get_result(value.id, difficulty) as HBResult
		var pass_results = result.note_ratings[HBJudge.JUDGE_RATINGS.FINE] + result.note_ratings[HBJudge.JUDGE_RATINGS.COOL]
		pass_results = float(pass_results / float(result.total_notes))
		var score_text = "%s - %.2f" % [HBUtils.find_key(HBResult.RESULT_RATING, result.get_result_rating()), pass_results * 100.0]
		score_text += " %"
		score_label.text = score_text
	else:
		score_label.hide()
func hover():
	add_stylebox_override("normal", hover_style)

func stop_hover():
	add_stylebox_override("normal", normal_style)
	
func _process(delta):
	modulate.a = lerp(modulate.a, target_opacity, LERP_SPEED*delta)

func _on_pressed():
	if song is HBPPDSong:
		if song.audio == "":
			prev_focus = get_focus_owner()
			$PPDAudioBrowseWindow.popup_centered_ratio(0.5)
			return
	emit_signal("song_selected", song)
#	var new_scene = preload("res://rythm_game/rhythm_game.tscn")
#	var scene = new_scene.instance()
#	get_tree().current_scene.queue_free()
#	get_tree().root.add_child(scene)
#	get_tree().current_scene = scene
#	scene.set_song(song)

func _on_ppd_audio_selected(path: String):
	var directory = Directory.new()
	song.audio = path.get_file()
	var song_path = song.get_song_audio_res_path()
	directory.copy(path, song_path)

func _on_PPDAudioBrowseWindow_accept():
	var dialog = MouseTrap.file_dialog as FileDialog
	dialog.mode = FileDialog.MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = ["*.ogg ; OGG"]
	dialog.popup_centered_ratio()
	dialog.connect("popup_hide", self, "_on_PPDAudioBrowseWindow_cancel", [], CONNECT_ONESHOT)
	dialog.connect("file_selected", self, "_on_ppd_audio_selected", [], CONNECT_ONESHOT)


func _on_PPDAudioBrowseWindow_cancel():
	if prev_focus:
		prev_focus.grab_focus()
