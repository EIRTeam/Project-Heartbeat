extends HBoxContainer

var icon_pack = "" setget set_icon_pack

var loading_thread = Thread.new()

onready var note_texture_rects = {
	"UP": get_node("VBoxContainer/UP"),
	"DOWN": get_node("VBoxContainer/DOWN"),
	"LEFT": get_node("VBoxContainer/LEFT"),
	"RIGHT": get_node("VBoxContainer/RIGHT")
}

func _preload_graphics_thread(userdata):
	var graphics = IconPackLoader.preload_graphics(IconPackLoader.packs[userdata.icon_pack])
	call_deferred("_on_graphics_preloaded", graphics)
	
func _on_graphics_preloaded(graphics):
	loading_thread.wait_to_finish()
	note_texture_rects.UP.texture = graphics.UP.note
	note_texture_rects.DOWN.texture = graphics.DOWN.note
	note_texture_rects.LEFT.texture = graphics.LEFT.note
	note_texture_rects.RIGHT.texture = graphics.RIGHT.note

func set_icon_pack(val):
	if val != icon_pack:
		icon_pack = val
		$Label.text = IconPackLoader.packs[icon_pack].name
		loading_thread.start(self, "_preload_graphics_thread", {"icon_pack": icon_pack})

