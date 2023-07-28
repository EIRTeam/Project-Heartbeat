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
var data: HBSteamUGCItem
var item_owner: HBSteamFriend

func _ready():
	super._ready()
	
func set_data(_data: HBSteamUGCItem):
	# HACKHACKHACK: requests need to be in tree?
	data = _data
	request = HTTPRequestQueue.add_request(data.preview_image_url)
	request.connect("request_completed", Callable(self, "_on_request_completed"))
	title_label.text = data.title
	romanized_title_label.text = ""
	if data.get_meta("item") is HBSong:
		if UserSettings.user_settings.romanized_titles_enabled:
			if not data.get_meta("item").romanized_title.is_empty():
				romanized_title_label.text = data.get_meta("item").romanized_title
	item_owner = data.owner
	if item_owner.request_user_information(true):
		item_owner.information_updated.connect(self.update_author_label)
	else:
		update_author_label()
	if data.item_state & SteamworksConstants.ITEM_STATE_SUBSCRIBED:
		subscribed_tick.show()
	else:
		subscribed_tick.hide()
	if data.votes_up + data.votes_down == 0:
		stars_panel.hide()
	else:
		var score = data.votes_up / float(data.votes_down + data.votes_up)
		stars_progress.value = score
	if _data.has_tag("Charts"):
		difficulty_panel.show()
		difficulty_label.text = "x?"
		if data.get_meta("item") is HBSong:
			var song := data.get_meta("item") as HBSong
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
	var pers = data.owner.persona_name
	author_label.text = pers
