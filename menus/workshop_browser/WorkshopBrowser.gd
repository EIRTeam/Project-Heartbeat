extends HBMenu

class_name HBWorkshopBrowser

const k_EUGCQuery_RankedByTextSearch = 11
const EUGCQuery_RankedByTrend = 3
const EUGCMatchingUGCType_Items_ReadyToUse = 2
const THUMBNAIL_SCENE = preload("res://menus/workshop_browser/WorkshopItemThumbnail.tscn")
var query_handle

const RESULTS_PER_PAGE = 50.0

@onready var grid_container = get_node("MarginContainer/Control/ScrollContainer/GridContainer")
@onready var scroll_container: HBUniversalScrollList = get_node("MarginContainer/Control/ScrollContainer")
@onready var pagination_label = get_node("MarginContainer/Control/HBoxContainer/Label")
@onready var pagination_container = get_node("MarginContainer/Control/HBoxContainer")
@onready var loading_spinner = get_node("MarginContainer/CenterContainer2")
@onready var loading_spinner_animation_player = get_node("MarginContainer/CenterContainer2/AnimationPlayer")
@onready var pagination_back_button = get_node("MarginContainer/Control/HBoxContainer/HBHovereableButton")
@onready var pagination_forward_button = get_node("MarginContainer/Control/HBoxContainer/HBHovereableButton2")
@onready var search_prompt = get_node("HBConfirmationWindow")
@onready var search_title_label = get_node("MarginContainer/Control/HBoxContainer2/SearchTitle")
@onready var sort_by_container = get_node("Panel/MarginContainer/VBoxContainer")
@onready var sort_by_popup = get_node("Panel")
@onready var tag_button_container = get_node("MarginContainer/Control/HBoxContainer4/HBoxContainer3")
@onready var star_filter_panel_container: PanelContainer = get_node("%StarFilterPanelContainer")
@onready var star_filter_vbox_container: VBoxContainer = get_node("%StarFilterVBoxContainer")

var current_page = 1

@onready var pagination_debounce_timer = Timer.new()

var total_items = 0
var filter_by_stars := false

var _debounced_page = 1

var current_query: HBWorkshopBrowserQuery
var steam_query: HBSteamUGCQuery

var filter_tag : set = set_filter_tag

var is_menu_open := false

func get_filter_tags():
	var tags := []
	# when filtering by stars we shouldn't be using the "Charts" tag, this is to prevent us from
	# matching charts by it when using setMatchAnyTag
	if filter_by_stars and filter_tag == "Charts":
		for i in range(star_filter_vbox_container.get_child_count()):
			var checkbox: HBHovereableCheckbox = star_filter_vbox_container.get_child(i)
			if checkbox.button_pressed:
				tags.push_back(checkbox.get_meta("filter_name"))
	else:
		tags = [filter_tag]
	return tags
func set_filter_tag(val):
	filter_tag = val
	navigate_to_page(1, QueryRequestAll.get_default(get_filter_tags()))

class QueryRequestAll:
	extends HBWorkshopBrowserQuery
	var sort_mode: SteamworksConstants.UGCQuery
	var tags: Array
	func _init(_sort_mode: int, _tags: Array):
		sort_mode = _sort_mode
		tags = _tags
	func make_query(page: int) -> HBSteamUGCQuery:
		var query = HBSteamUGCQuery.create_query(SteamworksConstants.UGC_MATCHING_UGC_TYPE_ITEMS_READY_TO_USE)
		_apply_sort_mode(sort_mode, query)
		for tag in tags:
			query.with_tag(tag).match_any_tag().with_metadata(true).with_long_description(true)
		return query
	static func get_default(_tags: Array):
		return QueryRequestAll.new(SteamworksConstants.UGC_QUERY_RANKED_BY_TREND, _tags)
	func get_query_title() -> String:
		return sort_by_mode_to_string(sort_mode)
class QueryRequestSearch:
	extends HBWorkshopBrowserQuery
	var search_text: String
	var tags: Array
	func _init(_search_text: String, _tags: Array):
		search_text = _search_text
		tags = _tags
	func make_query(page: int) -> HBSteamUGCQuery:
		var query := HBSteamUGCQuery.create_query(SteamworksConstants.UGC_MATCHING_UGC_TYPE_ITEMS_READY_TO_USE)
		_apply_sort_mode(SteamworksConstants.UGC_QUERY_RANKED_BY_TEXT_SEARCH, query)
		query.where_search_text(search_text).with_metadata(true).match_any_tag().with_long_description(true)
		for tag in tags:
			query.with_tag(tag)
		query.request_page(page)
		return query
	func get_query_title() -> String:
		return "Search: \"%s\"" % [search_text]
		
func _ready():
	super._ready()
	star_filter_panel_container.hide()
	for filter_name in HBGame.CHART_DIFFICULTY_TAGS:
		var hovereable_checkbox: HBHovereableCheckbox = preload("res://menus/HBHovereableCheckbox.tscn").instantiate()
		hovereable_checkbox.text = "★ " + filter_name
		hovereable_checkbox.set_meta("filter_name", filter_name)
		star_filter_vbox_container.add_child(hovereable_checkbox)
	
	var button_filter_songs = HBHovereableButton.new()
	button_filter_songs.text = tr("Charts")
	button_filter_songs.connect("hovered", Callable(self, "set_filter_tag").bind("Charts"))
	
	var button_filter_skins = HBHovereableButton.new()
	button_filter_skins.text = tr("Skins")
	button_filter_skins.connect("hovered", Callable(self, "set_filter_tag").bind("Skins"))
	
	var button_filter_note_packs = HBHovereableButton.new()
	button_filter_note_packs.text = tr("Note Packs")
	button_filter_note_packs.connect("hovered", Callable(self, "set_filter_tag").bind("Note Packs"))
	tag_button_container.add_child(button_filter_songs)
	tag_button_container.add_child(button_filter_skins)
	tag_button_container.add_child(button_filter_note_packs)
	
	tag_button_container.next_action = "gui_tab_right"
	tag_button_container.prev_action = "gui_tab_left"
	
#	scroll_container.vertical_step = grid_container.columns
	pagination_back_button.connect("pressed", Callable(self, "_on_user_navigate_button_pressed").bind(-1))
	pagination_forward_button.connect("pressed", Callable(self, "_on_user_navigate_button_pressed").bind(1))
	pagination_debounce_timer.connect("timeout", Callable(self, "_on_pagination_debounce_timeout"))
	pagination_debounce_timer.one_shot = true
	pagination_debounce_timer.wait_time = 0.5
	add_child(pagination_debounce_timer)
	
	sort_by_container.orientation = HBSimpleMenu.ORIENTATION.VERTICAL
	
	# Add sort by buttons
	for sort_mode in HBWorkshopBrowserQuery.SORT_BY_MODES:
		var sort_by_mode_text = HBWorkshopBrowserQuery.sort_by_mode_to_string(sort_mode)
		var button = HBHovereableButton.new()
		button.text = sort_by_mode_text
		button.connect("pressed", Callable(self, "_on_sort_by_button_pressed").bind(sort_mode))
		sort_by_container.add_child(button)
	sort_by_popup.size.y = $Panel/MarginContainer.get_minimum_size().y
	sort_by_popup.hide()
	
func _on_menu_enter(force_hard_transition=false, args = {}):
	super._on_menu_enter(force_hard_transition, args)
	pagination_debounce_timer.stop()
	current_page = _debounced_page
	filter_by_stars = false
	for filter_checkbox in star_filter_vbox_container.get_children():
		if filter_checkbox is CheckBox:
			filter_checkbox.button_pressed = false
	
	if not "no_fetch" in args or args.no_fetch == false:
		filter_tag = "Charts"
		tag_button_container.select_button(0, false)
		navigate_to_page(current_page, QueryRequestAll.get_default(get_filter_tags()))
	scroll_container.grab_focus()
	is_menu_open = true

func _on_menu_exit(force_hard_transition = false):
	super._on_menu_exit(force_hard_transition)
	is_menu_open = false

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
	
func navigate_to_page(page_n: int, query: HBWorkshopBrowserQuery = null):
	HTTPRequestQueue.cancel_all_requests()
	if query:
		current_query = query
	scroll_container.release_focus()
	pagination_container.release_focus()
	loading_spinner.show()
	loading_spinner_animation_player.play("spin")
	current_page = page_n
	current_query.tags = get_filter_tags()
	if steam_query:
		steam_query.query_completed.disconnect(self._on_ugc_query_completed)
	steam_query = current_query.make_query(page_n)
	search_title_label.text = current_query.get_query_title()
	if filter_by_stars and filter_tag == "Charts":
		var min_stars := 10000000.0
		var max_stars := -1000000.0
		var had_any_stars := false
		for i in range(star_filter_vbox_container.get_child_count()):
			var cb: CheckBox = star_filter_vbox_container.get_child(i)
			if cb.button_pressed:
				had_any_stars = true
				var v: Array = HBGame.CHART_DIFFICULTY_TAGS[cb.get_meta("filter_name")]
				var min_: float = v[0]
				var max_: float = v[1]
				if min_ == -INF:
					min_ = 0
				min_stars = min(min_stars, min_)
				max_stars = max(max_stars, max_)
		if had_any_stars:
			var max_str: String = "10+" if max_stars == INF else str(int(max_stars))
			search_title_label.text += " (★ " + str(int(min_stars)) + "-" + max_str + ")"
	for i in range(grid_container.get_child_count()-1, -1, -1):
		var child = grid_container.get_child(i)
		grid_container.remove_child(child)
		child.queue_free()
	steam_query.request_page(page_n)
	steam_query.query_completed.connect(self._on_ugc_query_completed)
func update_pagination_label(page_n: int):
	var total_pages = get_total_pages()
	pagination_label.text = "%d/%d" % [page_n, total_pages]
	pagination_back_button.visible = page_n > 1
	pagination_forward_button.visible = page_n <  total_pages
func _on_ugc_query_completed(result: HBSteamUGCQueryPageResult):
	# is_menu_open is a bit of a hack, basically, you could open the workshop menu
	# then exit, and while the exit animation was playing, the request would arrive, which would
	# transfer focus to the workshop menu, which was no bueno because the menu you were transitioning
	# to would lose focus
	if not is_inside_tree() or not is_menu_open:
		return
	if result:
		loading_spinner.hide()
		loading_spinner_animation_player.stop()
		for i in range(grid_container.get_child_count()-1, -1, -1):
			var child = grid_container.get_child(i)
			grid_container.remove_child(child)
			child.queue_free()
		var item_results := result.results
		for i in range(item_results.size()):
			var data = item_results[i]
			var metadata = data.metadata
			var item = null
			if metadata:
				var test_json_conv = JSON.new()
				test_json_conv.parse(metadata)
				var parsed_json = test_json_conv.get_data()
				if parsed_json:
					item = HBSerializable.deserialize(parsed_json)
			var scene = THUMBNAIL_SCENE.instantiate()
			grid_container.add_child(scene)
			scene.connect("pressed", Callable(self, "_on_item_selected").bind(scene))
			data.set_meta("item", item)
			scene.set_data(data)
		if item_results.size() > 0:
			scroll_container.select_item(0)
		total_items = result.total_results
		update_pagination_label(current_page)
		if not search_prompt.visible and not sort_by_popup.visible:
			scroll_container.grab_focus()

func _unhandled_input(event):
	var prompt_visible: bool = search_prompt.visible or star_filter_panel_container.visible
	if event.is_action_pressed("gui_cancel"):
		HBGame.fire_and_forget_sound(HBGame.menu_back_sfx, HBGame.sfx_group)
		if star_filter_panel_container.visible:
			star_filter_panel_container.hide()
			filter_by_stars = star_filter_vbox_container.get_children().any(func (a: Button): return a.button_pressed)
			navigate_to_page(1)
		elif sort_by_popup.visible:
			sort_by_popup.hide()
			scroll_container.grab_focus()
		else:
			HTTPRequestQueue.cancel_all_requests()
			change_to_menu("main_menu")
	elif prompt_visible:
		pass # do nothing
	elif event.is_action_pressed("contextual_option"):
		star_filter_panel_container.position = (size / 2.0) - (star_filter_vbox_container.size / 2.0)
		star_filter_panel_container.show()
		star_filter_vbox_container.grab_focus()
	elif event.is_action_pressed("gui_sort_by"):
		sort_by_popup.show()
		sort_by_container.grab_focus()
	elif event.is_action_pressed("gui_search"):
		search_prompt.popup_centered()
	elif (event.is_action("gui_tab_right") or event.is_action("gui_tab_left")):
		tag_button_container._gui_input(event)


func _on_text_search_entered(text: String):
	if text.strip_edges() != "":
		navigate_to_page(1, QueryRequestSearch.new(text, get_filter_tags()))
	search_prompt.hide()

func _on_ScrollContainer_out_from_bottom():
	if get_total_pages() > 1:
		pagination_container.grab_focus()

func _on_sort_by_button_pressed(sort_by_mode: int):
	var query = QueryRequestAll.new(sort_by_mode, get_filter_tags())
	sort_by_popup.hide()
	navigate_to_page(1, query)
	scroll_container.grab_focus()

func _on_item_selected(scene):
	change_to_menu("workshop_browser_detail_view", false, {"item": scene.data, "item_image": scene.texture_rect.texture, "request": scene.request})

func _on_pagination_out_from_top() -> void:
	scroll_container.select_item(scroll_container.item_container.get_child_count()-1)
	scroll_container.grab_focus()
