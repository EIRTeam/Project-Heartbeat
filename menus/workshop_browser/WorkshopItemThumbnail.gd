extends HBHovereableButton

var request: HTTPRequest

@onready var texture_rect = get_node("MarginContainer/HBoxContainer/TextureRect")
@onready var title_label = get_node("MarginContainer/HBoxContainer/VBoxContainer/VBoxContainer/Label/TitleLabel")
@onready var romanized_title_label = get_node("MarginContainer/HBoxContainer/VBoxContainer/VBoxContainer/Label/RomanizedTitleLabel")
@onready var author_label = get_node("MarginContainer/HBoxContainer/VBoxContainer/VBoxContainer/Label2")
@onready var subscribed_tick = get_node("MarginContainer/HBoxContainer/TextureRect/Panel")
@onready var stars_progress = get_node("MarginContainer/HBoxContainer/VBoxContainer2/Panel2/TextureRect")
@onready var stars_panel = get_node("MarginContainer/HBoxContainer/VBoxContainer2/Panel2")
@onready var difficulty_panel = get_node("MarginContainer/HBoxContainer/VBoxContainer2/Panel3")
@onready var difficulty_label = get_node("MarginContainer/HBoxContainer/VBoxContainer2/Panel3/HBoxContainer/Label")
var data: HBWorkshopPreviewData

func _ready():
	super._ready()
	connect("resized", Callable(self, "_on_resized"))
	
func set_data(_data: HBWorkshopPreviewData):
	# HACKHACKHACK: requests need to be in tree?
	data = _data
	request = HTTPRequestQueue.add_request(data.preview_url)
	request.connect("request_completed", Callable(self, "_on_request_completed"))
	title_label.text = data.title
	romanized_title_label.text = ""
	if data.metadata is HBSong:
		if UserSettings.user_settings.romanized_titles_enabled:
			if not data.metadata.romanized_title.is_empty():
				romanized_title_label.text = data.metadata.romanized_title
	if not Steam.requestUserInformation(data.steam_id_owner, true):
		update_author_label()
	else:
		Steam.connect("persona_state_change", Callable(self, "_on_persona_state_changed"))
	if Steam.getItemState(data.item_id) & Steam.ITEM_STATE_SUBSCRIBED:
		subscribed_tick.show()
	else:
		subscribed_tick.hide()
	if data.up_votes + data.down_votes == 0:
		stars_panel.hide()
	else:
		var score = data.up_votes / float(data.down_votes + data.up_votes)
		stars_progress.value = score
	if _data.tag == "Charts":
		difficulty_panel.show()
		difficulty_label.text = "x?"
		if _data.metadata is HBSong:
			var song := _data.metadata as HBSong
			var min_stars = 100000000
			var max_stars = 0
			for difficulty in song.charts:
				var stars = song.charts[difficulty].stars
				min_stars = min(stars, min_stars)
				max_stars = max(stars, max_stars)
			difficulty_label.text = "x%d" % [min_stars]
			if min_stars != max_stars:
				difficulty_label.text += "-x%d" % [max_stars]
	else:
		difficulty_panel.hide()
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result == OK and response_code == 200:
		texture_rect.texture = HBUtils.array2texture(body)
		$TextureRect.texture = texture_rect.texture
func update_author_label():
	var pers = Steam.getFriendPersonaName(data.steam_id_owner)
	author_label.text = pers
func _on_persona_state_changed(steam_id: int, flags: int):
	var e = (flags & 0x0001) + (flags & 0x1000)
	if steam_id == data.steam_id_owner and e != 0:
		update_author_label()
func _on_resized():
	pass
#	rect_min_size.y = rect_size.x * 0.9


func _on_HBoxContainer_minimum_size_changed():
#	difficulty_panel.rect_min_size = $MarginContainer/VBoxContainer/TextureRect/Panel3/HBoxContainer.get_combined_minimum_size()
#	difficulty_panel.rect_min_size.x += 5
#	difficulty_panel.rect_size.x = 0
	pass
