extends HBUIComponent

class_name HBUISongTitle

onready var hbox_container := HBoxContainer.new()
onready var circle_logo_margin_container := MarginContainer.new()
onready var circle_logo_texture_rect := TextureRect.new()
onready var title_label := HBUIDynamicLabel.new()
onready var artist_label := HBUIDynamicLabel.new()

var artist_font := HBUIFont.new() setget set_artist_font
var title_font := HBUIFont.new() setget set_title_font
var element_separation := 15 setget set_element_separation

func set_element_separation(val):
	element_separation = val
	if is_inside_tree():
		hbox_container.add_constant_override("separation", element_separation)

func set_artist_font(val):
	artist_font = val
	if is_inside_tree():
		set_control_font(artist_label, "font", artist_font)

func set_title_font(val):
	title_font = val
	if is_inside_tree():
		set_control_font(title_label, "font", title_font)

static func get_component_id() -> String:
	return "song_title"
	
static func get_component_name() -> String:
	return "Song Title Label"

func get_hb_inspector_whitelist() -> Array:
	var whitelist := .get_hb_inspector_whitelist()
	whitelist.append_array([
		"artist_font", "title_font", "element_separation"
	])
	return whitelist

func _ready():
	circle_logo_texture_rect.expand = true
	circle_logo_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	title_label.text = "今でも... 2012 (Imademo 2012)"
	artist_label.text = "のあ Artist name"
	artist_label.uppercase = true
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	artist_label.valign = Label.VALIGN_BOTTOM
	title_label.valign = Label.VALIGN_BOTTOM
	
	add_child(hbox_container)
	circle_logo_margin_container.add_child(circle_logo_texture_rect)
	circle_logo_margin_container.hide()
	hbox_container.add_child(circle_logo_margin_container)
	hbox_container.add_child(artist_label)
	hbox_container.add_child(title_label)
	hbox_container.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	
	artist_font.use_filter = true
	artist_font.use_mipmaps = true
	
	title_font.use_filter = true
	title_font.use_mipmaps = true
	
	set_element_separation(element_separation)
	set_artist_font(artist_font)
	set_title_font(title_font)
	connect("resized", self, "_on_resized")

func _on_resized():
	if circle_logo_texture_rect.texture:
		var image = circle_logo_texture_rect.texture.get_data() as Image
		var ratio = image.get_width() / image.get_height()
		var new_size = Vector2(hbox_container.rect_size.y * ratio, hbox_container.rect_size.y)
		new_size.x = clamp(new_size.x, 0, 250)
		circle_logo_margin_container.rect_min_size = new_size

func set_song(song: HBSong, assets, variant := -1):
	circle_logo_margin_container.hide()
	if not assets:
		var circle_logo_path = song.get_song_circle_logo_image_res_path()
		if circle_logo_path:
			circle_logo_texture_rect.show()
			var image = HBUtils.image_from_fs(circle_logo_path)
			var it = ImageTexture.new()
			it.create_from_image(image, Texture.FLAGS_DEFAULT)
			circle_logo_texture_rect.texture = it
			_on_resized()
		else:
			circle_logo_margin_container.hide()
	else:
		if "circle_logo" in assets:
			if assets.circle_logo:
				circle_logo_margin_container.show()
				circle_logo_texture_rect.texture = assets.circle_logo
				_on_resized()
	title_label.text = song.get_visible_title(variant)
	artist_label.visible = !song.hide_artist_name
	if song.artist_alias != "":
		artist_label.text = song.artist_alias
	else:
		artist_label.text = song.artist

func _to_dict(resource_storage: HBInspectorResourceStorage) -> Dictionary:
	var out_dict := ._to_dict(resource_storage)
	out_dict["artist_font"] = serialize_font(artist_font, resource_storage)
	out_dict["title_font"] = serialize_font(title_font, resource_storage)
	out_dict["element_separation"] = element_separation
	return out_dict
	
func _from_dict(dict: Dictionary, cache: HBSkinResourcesCache):
	._from_dict(dict, cache)
	deserialize_font(dict.get("artist_font", {}), artist_font, cache)
	deserialize_font(dict.get("title_font", {}), title_font, cache)
	element_separation = dict.get("element_separation", 15)
