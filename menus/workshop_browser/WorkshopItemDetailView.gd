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
var item_data: HBSteamUGCItem
var installing = false
var image_request: HTTPRequest
var item_data_owner: HBSteamFriend
func _ready():
	super._ready()
	description_margin_container.connect("minimum_size_changed", Callable(self, "_on_description_margin_minimum_size_changed"))
	unsubscribed_confirmation_window.connect("hide", Callable(buttons_container, "grab_focus"))
	PlatformService.service_provider.ugc_provider.connect("ugc_item_installed", Callable(self, "_on_ugc_item_installed"))
func _on_menu_enter(force_hard_transition=false, args = {}):
	super._on_menu_enter(force_hard_transition, args)
	installing = false
	if "item" in args:
		var item = args.item as HBSteamUGCItem
		item_data = item
		item_data_owner = item_data.owner
		var item_state = item.item_state
		unsubscribe_button.visible = item_state & SteamworksConstants.ITEM_STATE_SUBSCRIBED
		subscribe_button.visible = !unsubscribe_button.visible
		
		if item_state != 0:
			var song_id = "ugc_%d" % [item_data.item_id]
			show_in_song_list_button.visible = song_id in SongLoader.songs
		else:
			show_in_song_list_button.hide()
		buttons_container.grab_focus()
		title_label.text = item.title
		up_vote_label.text = str(item.votes_up)
		down_vote_label.text = str(item.votes_down)
		description_label.text = item.description
		print(item.description)
		
		star_progress.visible = (item.votes_up + item.votes_down) != 0
		if item.votes_up + item.votes_down != 0:
			star_progress.value = item.votes_up / float(item.votes_up + item.votes_down)
		if not item_data_owner.request_user_information(true):
			update_author_label()
		else:
			item_data_owner.information_updated.connect(self._on_persona_state_changed)
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
	var pers = item_data_owner.persona_name
	author_label.text = pers
func _on_persona_state_changed():
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
	item_data.subscribe()
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
				#TODOSW4 fix ytdlp
				pass
				#item.cache_data()
			show_in_song_list_button.show()


func _on_UnsubscribeButton_pressed():
	if item_data.item_state & SteamworksConstants.ITEM_STATE_SUBSCRIBED:
		item_data.unsubscribe()
		unsubscribed_confirmation_window.popup_centered()


func _on_Label_meta_clicked(meta):
	OS.shell_open(meta)
