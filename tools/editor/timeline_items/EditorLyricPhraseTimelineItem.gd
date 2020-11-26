extends "EditorTimelineItem.gd"
class_name EditorLyricPhraseTimelineItem

signal phrases_changed

onready var lyric_label = get_node("LyricsLabel")
onready var start_end_label = get_node("StartEndLabel")

func _init():
	data = HBLyricsPhrase.new()

func _ready():
	update_label()
	start_end_label.connect("mouse_click", self, "_gui_input")
func update_label():
	start_end_label.mouse_filter = MOUSE_FILTER_STOP
	if data is HBLyricsPhraseStart:
		start_end_label.text = "PStart"
	elif data is HBLyricsPhraseEnd:
		start_end_label.text = "PEnd"
	elif data is HBLyricsLyric:
		lyric_label.text = data.value
		start_end_label.mouse_filter = MOUSE_FILTER_IGNORE

func get_editor_size():
	var width = 3
	if data is HBLyricsLyric:
		width = 100
	return Vector2(width, rect_size.y)

func sync_value(value):
	if value == "value":
		update_label()
		emit_signal("phrases_changed")
	if value == "time":
		emit_signal("phrases_changed")

func get_click_rect():
	if data is HBLyricsLyric:
		return .get_click_rect()
	else:
		return start_end_label.get_global_rect()

func _draw():
	if not data is HBLyricsLyric:
		var color = Color.red
		
		if data is HBLyricsPhraseEnd:
			color = Color.blue
		
		draw_rect(Rect2(Vector2.ZERO, Vector2(3, rect_size.y)), color)
