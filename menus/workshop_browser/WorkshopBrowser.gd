extends HBMenu

class_name HBWorkshopBrowser

const k_EUGCQuery_RankedByTextSearch = 11
const EUGCQuery_RankedByTrend = 3
const EUGCMatchingUGCType_Items_ReadyToUse = 2
const THUMBNAIL_SCENE = preload("res://menus/workshop_browser/WorkshopItemThumbnail.tscn")
var query_handle

const RESULTS_PER_PAGE = 50.0

onready var grid_container = get_node("MarginContainer/Control/ScrollContainer/GridContainer")
onready var scroll_container = get_node("MarginContainer/Control/ScrollContainer")
onready var pagination_label = get_node("MarginContainer/Control/HBoxContainer/Label")
onready var pagination_container = get_node("MarginContainer/Control/HBoxContainer")
onready var loading_spinner = get_node("MarginContainer/CenterContainer2")
onready var loading_spinner_animation_player = get_node("MarginContainer/CenterContainer2/AnimationPlayer")
onready var pagination_back_button = get_node("MarginContainer/Control/HBoxContainer/HBHovereableButton")
onready var pagination_forward_button = get_node("MarginContainer/Control/HBoxContainer/HBHovereableButton2")
onready var search_prompt = get_node("HBConfirmationWindow")
onready var search_title_label = get_node("MarginContainer/Control/HBoxContainer2/SearchTitle")
onready var sort_by_container = get_node("Panel/MarginContainer/VBoxContainer")
onready var sort_by_popup = get_node("Panel")
onready var tag_button_container = get_node("MarginContainer/Control/HBoxContainer4/HBoxContainer3")

var current_page = 1

onready var pagination_debounce_timer = Timer.new()

var total_items = 0

var _debounced_page = 1

var current_query: HBWorkshopBrowserQuery

var filter_tag setget set_filter_tag

func set_filter_tag(val):
	filter_tag = val
	navigate_to_page(1, QueryRequestAll.get_default(filter_tag))

class QueryRequestAll:
	extends HBWorkshopBrowserQuery
	var sort_mode: int
	var tag: String
	func _init(_sort_mode: int, _tag: String):
		sort_mode = _sort_mode
		tag = _tag
	func make_query(page: int) -> int:
		var handle = Steam.createQueryAllUGCRequest(sort_mode, EUGCMatchingUGCType_Items_ReadyToUse, Steam.getAppID(), Steam.getAppID(), page)
		if tag:
			Steam.addRequiredTag(handle, tag)
		Steam.setReturnMetadata(handle, true)
		Steam.setReturnLongDescription(handle, true)
		return handle
	static func get_default(_tag: String):
		return QueryRequestAll.new(HBWorkshopBrowserQuery.SORT_BY_MODES.k_EUGCQuery_RankedByTrend, _tag)
	func get_query_title() -> String:
		return sort_by_mode_to_string(sort_mode)
class QueryRequestSearch:
	extends HBWorkshopBrowserQuery
	var search_text: String
	var tag: String
	func _init(_search_text: String, _tag: String):
		search_text = _search_text
		tag = _tag
	func make_query(page: int) -> int:
		var handle = Steam.createQueryAllUGCRequest(k_EUGCQuery_RankedByTextSearch, EUGCMatchingUGCType_Items_ReadyToUse, Steam.getAppID(), Steam.getAppID(), page)
		Steam.setSearchText(handle, search_text)
		Steam.setReturnMetadata(handle, true)
		if tag:
			Steam.addRequiredTag(handle, tag)
		Steam.setReturnLongDescription(handle, true)
		return handle
	func get_query_title() -> String:
		return "Search: \"%s\"" % [search_text]
		
func _ready():
	var button_filter_songs = HBHovereableButton.new()
	button_filter_songs.text = tr("Charts")
	button_filter_songs.connect("hovered", self, "set_filter_tag", ["Charts"])
	var button_filter_resource_packs = HBHovereableButton.new()
	button_filter_resource_packs.text = tr("Resource Packs")
	button_filter_resource_packs.connect("hovered", self, "set_filter_tag", ["Resource Packs"])
	tag_button_container.add_child(button_filter_songs)
	tag_button_container.add_child(button_filter_resource_packs)
	
	tag_button_container.next_action = "gui_tab_right"
	tag_button_container.prev_action = "gui_tab_left"
	
	Steam.connect("ugc_query_completed", self, "_on_ugc_query_completed")
	scroll_container.vertical_step = grid_container.columns
	pagination_back_button.connect("pressed", self, "_on_user_navigate_button_pressed", [-1])
	pagination_forward_button.connect("pressed", self, "_on_user_navigate_button_pressed", [1])
	pagination_debounce_timer.connect("timeout", self, "_on_pagination_debounce_timeout")
	pagination_debounce_timer.one_shot = true
	pagination_debounce_timer.wait_time = 0.5
	add_child(pagination_debounce_timer)
	
	sort_by_container.orientation = HBSimpleMenu.ORIENTATION.VERTICAL
	
	# Add sort by buttons
	for sort_mode in HBWorkshopBrowserQuery.SORT_BY_MODES.values():
		var sort_by_mode_text = HBWorkshopBrowserQuery.sort_by_mode_to_string(sort_mode)
		var button = HBHovereableButton.new()
		button.text = sort_by_mode_text
		button.connect("pressed", self, "_on_sort_by_button_pressed", [sort_mode])
		sort_by_container.add_child(button)
	sort_by_popup.rect_size.y = $Panel/MarginContainer.get_minimum_size().y
	sort_by_popup.hide()
func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	pagination_debounce_timer.stop()
	current_page = _debounced_page
	filter_tag = "Charts"
	if not "no_fetch" in args or args.no_fetch == false:
		tag_button_container.select_button(0, false)
		navigate_to_page(current_page, QueryRequestAll.get_default(filter_tag))
	scroll_container.grab_focus()

func _on_pagination_debounce_timeout():
	navigate_to_page(_debounced_page)
	
func get_total_pages():
	return ceil(total_items / RESULTS_PER_PAGE)
	
func _on_user_navigate_button_pressed(page_offset: int):
	var total_pages = get_total_pages()
	var new_page = clamp(_debounced_page + page_offset, 1, total_pages)
	update_pagination_label(new_page)
	if new_page != current_page:
		pagination_debounce_timer.stop()
		pagination_debounce_timer.start()
	else:
		pagination_debounce_timer.stop()
	_debounced_page = new_page
	
func navigate_to_page(page_n: int, query = null):
	HTTPRequestQueue.cancel_all_requests()
	if query:
		current_query = query
	scroll_container.release_focus()
	pagination_container.release_focus()
	loading_spinner.show()
	loading_spinner_animation_player.play("spin")
	current_page = page_n
	query_handle = current_query.make_query(page_n)
	search_title_label.text = current_query.get_query_title()
	for i in range(grid_container.get_child_count()-1, -1, -1):
		var child = grid_container.get_child(i)
		grid_container.remove_child(child)
		child.queue_free()
	Steam.sendQueryUGCRequest(query_handle)
func update_pagination_label(page_n: int):
	var total_pages = get_total_pages()
	pagination_label.text = "%d/%d" % [page_n, total_pages]
	pagination_back_button.visible = page_n > 1
	pagination_forward_button.visible = page_n <  total_pages
func _on_ugc_query_completed(handle, result, total_results, number_of_matching_results, cached):
	if not is_inside_tree():
		return
	if result == 1:
		if query_handle == handle:
			loading_spinner.hide()
			loading_spinner_animation_player.stop()
			for i in range(grid_container.get_child_count()-1, -1, -1):
				var child = grid_container.get_child(i)
				grid_container.remove_child(child)
				child.queue_free()
			for i in range(total_results):
				var data = Steam.getQueryUGCResult(handle, i)
				var metadata = Steam.getQueryUGCMetadata(handle, i)
				var item = null
				if metadata:
					var parsed_json = parse_json(metadata)
					if parsed_json:
						item = HBSerializable.deserialize(parsed_json)
				if data.result == 1:
					var url = Steam.getQueryUGCPreviewURL(handle, i)
					var prev_data = HBWorkshopPreviewData.new()
					var scene = THUMBNAIL_SCENE.instance()
					prev_data.preview_url = url
					prev_data.title = data.title
					prev_data.description = data.description
					prev_data.steam_id_owner = data.steamIDOwner
					prev_data.item_id = data.fileID
					prev_data.up_votes = data.votesUp
					prev_data.down_votes = data.votesDown
					prev_data.metadata = item
					prev_data.tag = filter_tag
					grid_container.add_child(scene)
					scene.connect("pressed", self, "_on_item_selected", [scene])
					scene.set_data(prev_data)
			if total_results > 0:
				scroll_container.select_item(0)
			total_items = number_of_matching_results
			update_pagination_label(current_page)
			if not search_prompt.visible and not sort_by_popup.visible:
				scroll_container.grab_focus()

func _unhandled_input(event):
	if event.is_action_pressed("gui_cancel"):
		if sort_by_popup.visible:
			sort_by_popup.hide()
			scroll_container.grab_focus()
		else:
			HTTPRequestQueue.cancel_all_requests()
			change_to_menu("main_menu")
	elif event.is_action_pressed("note_up") and not search_prompt.visible and not HBUtils.is_gui_directional_press("gui_up", event):
		sort_by_popup.show()
		sort_by_container.grab_focus()
	elif event.is_action_pressed("contextual_option") and not search_prompt.visible:
		search_prompt.popup_centered()
	elif (event.is_action("gui_tab_right") or event.is_action("gui_tab_left")) and not search_prompt.visible:
		tag_button_container._gui_input(event)


func _on_text_search_entered(text: String):
	if text.strip_edges() != "":
		navigate_to_page(1, QueryRequestSearch.new(text, filter_tag))
	search_prompt.hide()

func _on_ScrollContainer_out_from_bottom():
	if get_total_pages() > 1:
		pagination_container.grab_focus()

func _on_sort_by_button_pressed(sort_by_mode: int):
	var query = QueryRequestAll.new(sort_by_mode, filter_tag)
	sort_by_popup.hide()
	navigate_to_page(1, query)
	scroll_container.grab_focus()

func _on_item_selected(scene):
	change_to_menu("workshop_browser_detail_view", false, {"item": scene.data, "item_image": scene.texture_rect.texture, "request": scene.request})
