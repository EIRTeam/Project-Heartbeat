extends HBListContainer

func _ready():
	pass


func _on_EditorButton_pressed():
	get_tree().change_scene_to(preload("res://editor/Editor.tscn"))
