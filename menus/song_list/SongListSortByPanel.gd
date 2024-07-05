extends PanelContainer

class_name HBSongListSortByPanel

@onready var button_container: HBSimpleMenu = get_node("%ButtonContainer")
@onready var has_media_checkbox: CheckBox = get_node("%HasMediaCheckbox")
@onready var sort_by_option_button: HBHovereableOptionButton = get_node("%SortByOptionButton")
@onready var note_usage_option_button: HBHovereableOptionButton = get_node("%ChartStyleOptionButton")
@onready var filter_by_stars_slider_min: HBOptionMenuOptionRange = get_node("%FilterByStarsSliderMin")
@onready var filter_by_stars_slider_max: HBOptionMenuOptionRange = get_node("%FilterByStarsSliderMax")
@onready var filter_by_stars_checkbox: CheckBox = get_node("%FilterByStarsCheckbox")

signal sort_filter_settings_changed()
signal closed

var options_changed := false

var filter_settings: HBSongSortFilterSettings

var allowed_sort_by = {
	"title": tr("Sort by title"),
	"artist": tr("Sort by artist"),
	"highest_score": tr("Sort by highest difficulty"),
	"lowest_score": tr("Sort by lowest difficulty"),
	"creator": tr("Sort by chart creator name"),
	"bpm": tr("Sort by BPM"),
	"_added_time": tr("Sort by last subscribed"),
	"_times_played": tr("Sort by times played"),
	"_released_time": tr("Sort by last released"),
	"_updated_time": tr("Sort by last updated")
}

func _ready() -> void:	
	filter_by_stars_slider_max.text = tr("Maximum")
	filter_by_stars_slider_min.text = tr("Minimum")
	filter_by_stars_slider_max.changed.connect(func(value: int):
		filter_settings.star_filter_max = value
		if filter_settings.star_filter_max < filter_settings.star_filter_min:
			filter_settings.star_filter_min = filter_settings.star_filter_max
		update_star_filter()
		notify_filter_changed()
	)

	filter_by_stars_slider_min.changed.connect(func(value: int):
		filter_settings.star_filter_min = value
		if filter_settings.star_filter_min > filter_settings.star_filter_max:
			filter_settings.star_filter_max = filter_settings.star_filter_min
		update_star_filter()
		notify_filter_changed()
	)

	filter_by_stars_checkbox.toggled.connect(func(value: bool):
		filter_settings.star_filter_enabled = value
		update_star_filter()
		notify_filter_changed()
	)
	
	has_media_checkbox.toggled.connect(func(value: bool):
		filter_settings.filter_has_media_only = value
		notify_filter_changed()
	)
	
	sort_by_option_button.selected.connect(func(id: String):
		if filter_settings.filter_mode == "workshop":
			filter_settings.workshop_tab_sort_prop = id
		else:
			filter_settings.sort_prop = id
		notify_filter_changed()
	)
	
	note_usage_option_button.selected.connect(func(filter_mode: int):
		filter_settings.note_usage_filter_mode = filter_mode
		notify_filter_changed()
	)

func popup():
	populate_sort_by_list()
	populate_note_usage_filter_list()
	update_star_filter()
	update_media_filter()
	show()
	button_container.grab_focus()
	options_changed = false

func close():
	HBGame.fire_and_forget_sound(HBGame.menu_back_sfx, HBGame.sfx_group)
	hide()
	if options_changed:
		sort_filter_settings_changed.emit()
	closed.emit()
func _input(event: InputEvent) -> void:
	if button_container.has_focus() and button_container.selected_button in [filter_by_stars_slider_max, filter_by_stars_slider_min]:
		if event.is_action("gui_left") or event.is_action("gui_right"):
			button_container.selected_button._gui_input(event)
			get_viewport().set_input_as_handled()

func notify_filter_changed():
	options_changed = true

func populate_sort_by_list():
	var workshop_only_sort_by = ["_added_time", "_released_time", "_updated_time"]
	
	sort_by_option_button.clear()
	sort_by_option_button.set_block_signals(true)
	var sort_prop := filter_settings.sort_prop
	if filter_settings.filter_mode == "workshop":
		sort_prop = filter_settings.workshop_tab_sort_prop
	for sort_by in allowed_sort_by:
		if sort_by in workshop_only_sort_by and not UserSettings.user_settings.sort_filter_settings.filter_mode == "workshop":
			continue
		sort_by_option_button.add_item(allowed_sort_by[sort_by], sort_by)
		# We ensure the current sort mode is selected by default
		if sort_by == sort_prop:
			sort_by_option_button.selected_item = sort_by_option_button.get_item_count()-1
	sort_by_option_button.set_block_signals(false)

func populate_note_usage_filter_list():
	note_usage_option_button.clear()
	note_usage_option_button.set_block_signals(true)
	var translation_table := {
		HBSongSortFilterSettings.NoteUsageFilterMode.FILTER_MODE_ALL: tr("All notes", &"Chart style filter mode in song list sort & filter settings panel"),
		HBSongSortFilterSettings.NoteUsageFilterMode.FILTER_MODE_CONSOLE_ONLY: tr("Console notes only", &"Chart style filter mode in song list sort & filter settings panel"),
		HBSongSortFilterSettings.NoteUsageFilterMode.FILTER_MODE_ARCADE_ONLY: tr("Arcade notes only", &"Chart style filter mode in song list sort & filter settings panel")
	}
	assert(translation_table.size() == HBSongSortFilterSettings.NoteUsageFilterMode.size())
	for filter_mode in HBSongSortFilterSettings.NoteUsageFilterMode.values():
		
		var icon: Texture2D
		
		match filter_mode:
			HBSongSortFilterSettings.NoteUsageFilterMode.FILTER_MODE_CONSOLE_ONLY:
				icon = ResourcePackLoader.get_graphic("heart_note.png")
			HBSongSortFilterSettings.NoteUsageFilterMode.FILTER_MODE_ARCADE_ONLY:
				icon = ResourcePackLoader.get_graphic("slide_right_note.png")
				
		note_usage_option_button.add_item(translation_table[filter_mode], filter_mode, icon)
		
		if filter_mode == filter_settings.note_usage_filter_mode:
			note_usage_option_button.set_selected_item(note_usage_option_button.get_item_count()-1)
	note_usage_option_button.set_block_signals(false)


func update_media_filter():
	has_media_checkbox.set_block_signals(true)
	has_media_checkbox.button_pressed = filter_settings.filter_has_media_only
	has_media_checkbox.set_block_signals(false)

func update_star_filter():
	filter_by_stars_slider_min.set_block_signals(true)
	filter_by_stars_slider_min.set_value(filter_settings.star_filter_min)
	filter_by_stars_slider_min.set_block_signals(false)
	filter_by_stars_slider_max.set_block_signals(true)
	filter_by_stars_slider_max.set_value(filter_settings.star_filter_max)
	filter_by_stars_slider_max.set_block_signals(false)
	filter_by_stars_checkbox.set_block_signals(true)
	filter_by_stars_checkbox.button_pressed = filter_settings.star_filter_enabled
	filter_by_stars_checkbox.set_block_signals(false)
	filter_by_stars_slider_max.visible = filter_settings.star_filter_enabled
	filter_by_stars_slider_min.visible = filter_settings.star_filter_enabled
