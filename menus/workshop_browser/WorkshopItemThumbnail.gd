extends HBHovereableButton

var request: HTTPRequest

onready var texture_rect = get_node("MarginContainer/VBoxContainer/TextureRect")
onready var title_label = get_node("MarginContainer/VBoxContainer/VBoxContainer/Label")
onready var author_label = get_node("MarginContainer/VBoxContainer/VBoxContainer/Label2")
onready var subscribed_tick = get_node("MarginContainer/VBoxContainer/TextureRect/Panel")
onready var stars_progress = get_node("MarginContainer/VBoxContainer/TextureRect/Panel2/TextureRect")
onready var stars_panel = get_node("MarginContainer/VBoxContainer/TextureRect/Panel2")

var data: HBWorkshopPreviewData

func _ready():
	connect("resized", self, "_on_resized")
	
func set_data(_data: HBWorkshopPreviewData):
	# HACKHACKHACK: requests need to be in tree?
	data = _data
	request = HTTPRequestQueue.add_request(data.preview_url)
	request.connect("request_completed", self, "_on_request_completed")
	title_label.text = data.title
	if not Steam.requestUserInformation(data.steam_id_owner, true):
		update_author_label()
	else:
		Steam.connect("persona_state_change", self, "_on_persona_state_changed")
	# getItemState returns 0 when subscribed to an item
	if Steam.getItemState(data.item_id) != 0:
		subscribed_tick.show()
	else:
		subscribed_tick.hide()
	if data.up_votes + data.down_votes == 0:
		stars_panel.hide()
	else:
		var score = data.up_votes / float(data.down_votes + data.up_votes)
		stars_progress.value = score
func _on_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	if result == OK and response_code == 200:
		texture_rect.texture = HBUtils.array2texture(body)
func update_author_label():
	var pers = Steam.getFriendPersonaName(data.steam_id_owner)
	author_label.text = pers
func _on_persona_state_changed(steam_id: int, flags: int):
	var e = (flags & 0x0001) + (flags & 0x1000)
	if steam_id == data.steam_id_owner and e != 0:
		update_author_label()
func _on_resized():
	rect_min_size.y = rect_size.x * 1.0
