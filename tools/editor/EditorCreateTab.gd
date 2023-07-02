extends Control

signal create_note_type(note_type)
@onready var note_select_button = get_node("MarginContainer/VBoxContainer/NoteTypeSelectButton")
func _ready():
	for type_name in HBSerializable.get_serializable_types():
		var type = HBSerializable.get_serializable_types()[type_name]
		if type.can_show_in_editor():
			note_select_button.add_item(type_name.capitalize())
			note_select_button.set_item_metadata(note_select_button.get_item_count()-1, type)
	note_select_button.select(0)
	


func _on_create_note():
	emit_signal("create_note_type", note_select_button.get_item_metadata(note_select_button.selected))
