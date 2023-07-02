extends HBSongListItemBase

class_name HBSongListFolder

var folder: HBFolder

@onready var folder_name_control = get_node("Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/FolderName")
@onready var button = get_node("Control")

#onready var star_texture_rect = get_node("TextureRect")
signal folder_selected(folder)

func _ready():
	super._ready()
	button.connect("pressed", Callable(self, "emit_signal").bind("pressed"))

func set_folder(val: HBFolder):
	folder = val
	$Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/FolderName.text = folder.folder_name
	
	$Control/MarginContainer/HBoxContainer/MarginContainer/VBoxContainer/HBoxContainer2/SongCount.text = "%d Song(s) %d Folder(s)" % [folder.songs.size(), folder.subfolders.size()]
	emit_signal("folder_selected", folder)
#	stars_texture_rect.rect_position = Vector2(-88, -25)
#	star_texture_rect.rect_position = Vector2(-(star_texture_rect.rect_size.x/2.0), (rect_size.y / 2.0) - ((star_texture_rect.rect_size.y) / 2.0))

func _gui_input(event):
	if event.is_action_pressed("gui_accept") and not event.is_echo():
		emit_signal("folder_selected", folder)
#	var new_scene = preload("res://rythm_game/rhythm_game_controller.tscn")
#	var scene = new_scene.instance()
#	get_tree().current_scene.queue_free()
#	get_tree().root.add_child(scene)
#	get_tree().current_scene = scene
#	scene.set_song(song)

