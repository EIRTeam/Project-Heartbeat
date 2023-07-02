extends HBMenu

@onready var buttons_container = get_node("MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/HBoxContainer2/HBoxContainer2")
@onready var subscribe_button = get_node("MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/HBoxContainer2/HBoxContainer2/SubscribeButton")
@onready var unsubscribe_button = get_node("MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/HBoxContainer2/HBoxContainer2/UnsubscribeButton")
@onready var title_label = get_node("MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/HBoxContainer/VBoxContainer/Label")
@onready var up_vote_label = get_node("MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/HBoxContainer2/HBoxContainer/UpVoteLabel")
@onready var down_vote_label = get_node("MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/HBoxContainer2/HBoxContainer/DownVoteLabel")
@onready var description_label = get_node("MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/Panel/MarginContainer/Label")
@onready var description_panel = get_node("MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/Panel")
@onready var description_margin_container = get_node("MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/Panel/MarginContainer")
@onready var item_image_rect = get_node("MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer2/TextureRect")
@onready var star_progress = get_node("MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/HBoxContainer2/Control/TextureProgressBar")
@onready var show_in_song_list_button = get_node("MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/HBoxContainer2/HBoxContainer2/ShowInSongListButton")
@onready var unsubscribed_confirmation_window = get_node("UnsubscribedConfirmationWindow")
@onready var author_label = get_node("MarginContainer/VBoxContainer/HBoxContainer3/VBoxContainer/HBoxContainer/VBoxContainer/Label2")
var item_data: HBWorkshopPreviewData
var installing = false
var image_request: HTTPRequest
func _ready():
	super._ready()
	description_margin_container.connect("minimum_size_changed", Callable(self, "_on_description_margin_minimum_size_changed"))
	unsubscribed_confirmation_window.connect("hide", Callable(buttons_container, "grab_focus"))
	Steam.connect("persona_state_change", Callable(self, "_on_persona_state_changed"))
	PlatformService.service_provider.ugc_provider.connect("ugc_item_installed", Callable(self, "_on_ugc_item_installed"))
func _on_menu_enter(force_hard_transition=false, args = {}):
	super._on_menu_enter(force_hard_transition, args)
	installing = false
	if "item" in args:
		var item = args.item as HBWorkshopPreviewData
		item_data = item
		var item_state = Steam.getItemState(item.item_id)
		unsubscribe_button.visible = item_state & Steam.ITEM_STATE_SUBSCRIBED
		subscribe_button.visible = !unsubscribe_button.visible
		
		if item_state != 0:
			var song_id = "ugc_%d" % [item_data.item_id]
			show_in_song_list_button.visible = song_id in SongLoader.songs
		else:
			show_in_song_list_button.hide()
		buttons_container.grab_focus()
		title_label.text = item.title
		up_vote_label.text = str(item.up_votes)
		down_vote_label.text = str(item.down_votes)
		description_label.text = item.description
		
		star_progress.visible = (item.up_votes + item.down_votes) != 0
		if item.up_votes + item.down_votes != 0:
			star_progress.value = item.up_votes / float(item.up_votes + item.down_votes)
		if not Steam.requestUserInformation(item_data.steam_id_owner, true):
			update_author_label()
		else:
			Steam.connect("persona_state_change", Callable(self, "_on_persona_state_changed"))
		call_deferred("_on_description_margin_minimum_size_changed")
	if "item_image" in args:
		if args.item_image:
			item_image_rect.texture = args.item_image
		else:
			item_image_rect.texture = null
			if "request" in args:
				if is_instance_valid(image_request):
					image_request = args.request
					image_request.connect("request_completed", Callable(self, "_on_request_completed"))

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result == OK and response_code == 200:
		item_image_rect.texture = HBUtils.array2texture(body)

func _on_menu_exit(force_hard_transition = false):
	super._on_menu_exit(force_hard_transition)
	if image_request and is_instance_valid(image_request):
		image_request.disconnect("request_completed", Callable(self, "_on_request_completed"))

func update_author_label():
	var pers = Steam.getFriendPersonaName(item_data.steam_id_owner)
	author_label.text = pers
func _on_persona_state_changed(steam_id: int, flags: int):
	var e = (flags & 0x0001) + (flags & 0x1000)
	if steam_id == item_data.steam_id_owner and e != 0:
		update_author_label()

func _on_description_margin_minimum_size_changed():
	description_panel.custom_minimum_size.y = description_margin_container.get_minimum_size().y
	description_panel.size.y = 0

func _on_TextureRect_resized():
	item_image_rect.custom_minimum_size.y = item_image_rect.size.x

func _unhandled_input(event):
	if event.is_action_pressed("gui_cancel"):
		HBGame.fire_and_forget_sound(HBGame.menu_back_sfx, HBGame.sfx_group)
		change_to_menu("workshop_browser", false, { "no_fetch": true })

func _on_ShowInSongListButton_pressed():
	var song_id = "ugc_%d" % [item_data.item_id]
	change_to_menu("song_list", false, {"song": song_id, "force_filter": "workshop"})

func _on_SubscribeButton_pressed():
	installing = true
	Steam.subscribeItem(item_data.item_id)
	subscribe_button.hide()
	unsubscribe_button.show()
	buttons_container.select_button(unsubscribe_button.get_index())

func _on_ugc_item_installed(item_type, item):
	if installing and item and item.ugc_id == item_data.item_id:
		if item is HBSong:
			if UserSettings.user_settings.workshop_download_audio_only:
				if not UserSettings.user_settings.per_song_settings.has(item.id):
					UserSettings.user_settings.per_song_settings[item.id] = HBPerSongSettings.new()
				UserSettings.user_settings.per_song_settings[item.id].video_enabled = false
				UserSettings.save_user_settings()
			if not item.is_cached():
				item.cache_data()
			show_in_song_list_button.show()


func _on_UnsubscribeButton_pressed():
	if Steam.getItemState(item_data.item_id) != 0:
		Steam.unsubscribeItem(item_data.item_id)
		unsubscribed_confirmation_window.popup_centered()


func _on_Label_meta_clicked(meta):
	OS.shell_open(meta)
