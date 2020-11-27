extends Label

var phrases = []
var current_phrase: HBLyricsPhrase

const LYRIC_MARGIN = 200

onready var overlay_label = get_node("Label2")

var last_time = 0

export(DynamicFont) var font1
export(DynamicFont) var font2

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
			if time < c_phrase.get_min_time() - LYRIC_MARGIN:
				hide()
				break
			else:
				show()
		else:
			# case 2: in the middle of a phrase
			if time < c_phrase.get_max_time() and time > c_phrase.get_min_time():
				show()
				set_current_phrase(c_phrase)
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
					
			# case 4: last
			if i == phrases.size() - 1:
				if time > c_phrase.get_max_time():
					hide()
				else:
					show()
	if current_phrase:
		var curr_visible_characters = 0
		for phrase in current_phrase.lyrics:
			if time >= phrase.time:
				curr_visible_characters += phrase.value.length() - phrase.value.count(" ")
		overlay_label.visible_characters = curr_visible_characters
func set_current_phrase(phrase: HBLyricsPhrase):
	if phrase != current_phrase:
		current_phrase = phrase
		update_labels()
	
func _ready():
	update_labels()
	connect("resized", self, "_on_resized")
	align = UserSettings.user_settings.get_lyrics_alignment()
	overlay_label.align = UserSettings.user_settings.get_lyrics_alignment()
	
	anchor_bottom = UserSettings.user_settings.get_lyrics_position()
	anchor_top = UserSettings.user_settings.get_lyrics_position()
	
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
	var font_size = int(BASE_FONT_SIZE * rect_size.x / 1920.0)
	var outline_size = int(BASE_OUTLINE_SIZE * rect_size.x / 1920.0)
	font1.size = font_size
	font1.outline_size = outline_size
	font2.size = font_size
	font2.outline_size = outline_size
func set_phrases(array: Array):
	phrases = array
	overlay_label.text = ""
	text = ""
	show()
	if phrases.size() > 0:
		set_current_phrase(phrases[0])
	_on_game_time_changed(last_time)
