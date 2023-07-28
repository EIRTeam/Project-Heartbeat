extends TabbedContainerTab

var song: HBSong
var difficulty: String
var include_modifiers: bool = false
var page: int = 1
var total_pages = 1

var already_have_result = false

@onready var leaderboard = get_node("VBoxContainer2/VBoxContainer/Panel/ScrollContainer/MarginContainer/Panel") as LeaderboardView
@onready var scroll_container = get_node("VBoxContainer2/VBoxContainer/Panel/ScrollContainer")
@onready var margin_container = get_node("VBoxContainer2/VBoxContainer/Panel/ScrollContainer/MarginContainer")
var scroll_pos = 0.0
const SCROLL_SPEED = 1000.0

@onready var pagination_buttons = get_node("VBoxContainer2/VBoxContainer/HBoxContainer")

@onready var prev_page_button = get_node("VBoxContainer2/VBoxContainer/HBoxContainer/HBHovereableButton")
@onready var next_page_button = get_node("VBoxContainer2/VBoxContainer/HBoxContainer/HBHovereableButton2")
@onready var pages_label = get_node("VBoxContainer2/VBoxContainer/HBoxContainer/Label")
func _enter_tab():
	super._enter_tab()
	if not already_have_result:
		leaderboard.fetch_entries(song, difficulty, include_modifiers, page)
		already_have_result = true

func reset():
	already_have_result = false
	page = 1
	total_pages = 1

func _ready():
	scroll_container.get_v_scroll_bar().add_theme_stylebox_override("grabber", preload("res://styles/Grabber.tres"))
	scroll_container.get_v_scroll_bar().add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
	scroll_container.get_v_scroll_bar().add_theme_icon_override("increment", ImageTexture.new())
	scroll_container.get_v_scroll_bar().add_theme_icon_override("decrement", ImageTexture.new())
	scroll_container.get_v_scroll_bar().custom_minimum_size = Vector2(20, 0)
	prev_page_button.connect("pressed", Callable(self, "_on_prev_page_pressed"))
	next_page_button.connect("pressed", Callable(self, "_on_next_page_pressed"))
	leaderboard.connect("entries_received", Callable(self, "_on_entries_received"))
	leaderboard.connect("entries_request_failed", Callable(pagination_buttons, "hide"))
	pagination_buttons.stop_hover_on_focus_exit = false
	
func _on_entries_received(handle, entries, _total_pages):
	pagination_buttons.visible = _total_pages > 1
	total_pages = _total_pages
	update_pages_label()
	# HACK: If we don't do this scroll bars break randomly
	margin_container.hide()
	margin_container.show()
func update_pages_label():
	next_page_button.show()
	prev_page_button.show()
	if total_pages <= 1:
		prev_page_button.hide()
		next_page_button.hide()
	else:
		if page == 1:
			prev_page_button.hide()
			pagination_buttons.select_button(next_page_button.get_index())
		elif page >= total_pages:
			next_page_button.hide()
			pagination_buttons.select_button(prev_page_button.get_index())
	pages_label.text = "%d/%d" % [page, total_pages]
	
func _on_prev_page_pressed():
	var old_page = page
	page = clamp(page-1, 1, total_pages)
	if page != old_page:
		leaderboard.fetch_entries(song, difficulty, include_modifiers, page)
	
func _on_next_page_pressed():
	var old_page = page
	page = clamp(page+1, 1, total_pages)
	if page != old_page:
		leaderboard.fetch_entries(song, difficulty, include_modifiers, page)
	
func get_leaderboard_view():
	return $ScrollContainer/Panel
	
func _unhandled_input(event):
	pagination_buttons._gui_input(event)
	
func _process(delta):
	var speed = Input.get_action_strength("gui_down") - Input.get_action_strength("gui_up")
	
	if abs(scroll_container.scroll_vertical - scroll_pos) > 1:
		scroll_pos = scroll_container.scroll_vertical
	
	if speed != 0:
		scroll_pos += speed * SCROLL_SPEED * delta
		scroll_pos = clamp(scroll_pos, 0, scroll_container.get_child(0).size.y - scroll_container.size.y)
		scroll_container.scroll_vertical = scroll_pos
