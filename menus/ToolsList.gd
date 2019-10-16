extends HBListContainer

func _ready():
	pass


func _on_EditorButton_pressed():
	get_tree().change_scene_to(preload("res://tools/editor/Editor.tscn"))


func _on_SongMetaEditorButton_pressed():
	get_tree().change_scene_to(preload("res://tools/song_meta_editor/SongMetaEditor.tscn"))
