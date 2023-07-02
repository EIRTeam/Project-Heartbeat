extends Label

var phrases = []
var current_phrase: HBLyricsPhrase

const LYRIC_MARGIN = 200

@onready var overlay_label = get_node("Label2")

var last_time = 0

@export var font1: FontFile
@export var font2: FontFile

const BASE_FONT_SIZE = 45
const BASE_OUTLINE_SIZE = 5

func _on_game_time_changed(time: int):
	if not UserSettings.user_settings.lyrics_enabled:
		hide()
		return
	show()
	for i in range(phrases.size()):
		var c_phrase := phrases[i] as HBLyricsPhrase
		
		if i == 0:
			
			if phrases.size() == 1:
				if time > c_phrase.get_max_time():
					hide()
					break
			
			if time < c_phrase.get_min_time() - LYRIC_MARGIN:
				hide()
				break
			else:
				set_current_phrase(c_phrase)
				show()
		else:
			# case 2: in the middle of a phrase
			if time < c_phrase.get_max_time() and time > c_phrase.get_min_time():
				show()
				set_current_phrase(c_phrase)
				break
			# case 4: last
			if i == phrases.size() - 1:
				if time > c_phrase.get_max_time():
					hide()
					break
				elif c_phrase.get_min_time() < time:
					show()
					break
			
			# case 1: between two phrases
			# will show phrase 200 ms before second one
			var prev_phrase = phrases[i-1] as HBLyricsPhrase
			if time < c_phrase.get_min_time() and time > prev_phrase.get_max_time():
				if c_phrase.get_min_time() - time <= LYRIC_MARGIN:
					show()
					set_current_phrase(c_phrase)
					break
				else:
					hide()
					set_current_phrase(prev_phrase)
					break
	if current_phrase:
		var curr_visible_characters = 0
		var first = true
		for phrase in current_phrase.lyrics:
			if time >= phrase.time:
				curr_visible_characters += phrase.value.length() - phrase.value.count(" ")
				if first and phrase.value.begins_with(" "):
					curr_visible_characters += 1
			first = false
		if current_phrase.lyrics.size() <= 1 and time < current_phrase.end_time:
			curr_visible_characters = -1
		elif current_phrase.end_time < time:
			hide()
		overlay_label.visible_characters = curr_visible_characters
func set_current_phrase(phrase: HBLyricsPhrase):
	if phrase != current_phrase:
		current_phrase = phrase
		update_labels()
	
func _ready():
	update_labels()
	connect("resized", Callable(self, "_on_resized"))
	horizontal_alignment = UserSettings.user_settings.get_lyrics_halign()
	overlay_label.horizontal_alignment = horizontal_alignment
	
	vertical_alignment = UserSettings.user_settings.get_lyrics_valign()
	overlay_label.vertical_alignment = vertical_alignment
	
	$Label2.add_theme_color_override("font_color", UserSettings.user_settings.get_lyrics_color())
	add_theme_font_override("font", font1)
	$Label2.add_theme_font_override("font", font2)
	_on_resized()
	
	
func update_labels():
	if current_phrase:
		var ps = current_phrase.get_phrase_string()
		text = ps
		overlay_label.text = ps
		overlay_label.visible_characters = 0
	else:
		overlay_label.text = ""
		text = ""
	
func _on_resized():
	var font_size = int(BASE_FONT_SIZE * size.x / 1920.0)
	var outline_size = int(BASE_OUTLINE_SIZE * size.x / 1920.0)
	add_theme_font_size_override("font_size", font_size)
	add_theme_constant_override("outline_size", outline_size)
	$Label2.add_theme_font_size_override("font_size", font_size)
	$Label2.add_theme_constant_override("outline_size", outline_size)
func set_phrases(array: Array):
	phrases = array
	overlay_label.text = ""
	text = ""
	show()
	if phrases.size() > 0:
		set_current_phrase(phrases[0])
	else:
		current_phrase = null
	_on_game_time_changed(last_time)
	update_labels()
