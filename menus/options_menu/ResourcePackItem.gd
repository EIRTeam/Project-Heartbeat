extends HBHovereableButton

onready var pack_icon := get_node("MarginContainer/HBoxContainer/HBoxContainer/TextureRect")

onready var title_label := get_node("MarginContainer/HBoxContainer/VBoxContainer/TitleLabel")
onready var author_label := get_node("MarginContainer/HBoxContainer/VBoxContainer/AuthorLabel")
onready var description_label := get_node("MarginContainer/HBoxContainer/VBoxContainer/DescriptionLabel")

onready var checked_panel := get_node("HBoxContainer/CheckedPanel")
onready var note_override_panel := get_node("HBoxContainer/CheckedPanel2")

var resource_pack: HBResourcePack

func set_pack(_resource_pack: HBResourcePack):
	resource_pack = _resource_pack
	var pack_icon_image := resource_pack.get_pack_icon()
	if pack_icon_image:
		var icon_texture := ImageTexture.new()
		icon_texture.create_from_image(pack_icon_image)
		pack_icon.texture = icon_texture
	title_label.text = resource_pack.pack_name
	if resource_pack.pack_author_name:
		author_label.show()
		author_label.text = "by " + resource_pack.pack_author_name
	else:
		author_label.hide()
	
	if resource_pack.pack_description:
		description_label.show()
		description_label.bbcode_text = resource_pack.pack_description
	else:
		description_label.hide()

func set_checked(checked: bool):
	checked_panel.visible = checked

func set_note_override(checked: bool):
	note_override_panel.visible = checked
