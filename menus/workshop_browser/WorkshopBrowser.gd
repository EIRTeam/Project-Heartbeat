extends Control

const EUGCQuery_RankedByTrend = 3
const EUGCMatchingUGCType_Items_ReadyToUse = 2
const THUMBNAIL_SCENE = preload("res://menus/workshop_browser/WorkshopItemThumbnail.tscn")

onready var grid_container = get_node("ScrollContainer/GridContainer")
onready var scroll_container = get_node("ScrollContainer")
var query_handle

var current_selected_item = 0

func _ready():
	Steam.connect("ugc_query_completed", self, "_on_ugc_query_completed")
	query_handle = Steam.createQueryAllUGCRequest(EUGCQuery_RankedByTrend, EUGCMatchingUGCType_Items_ReadyToUse, Steam.getAppID(), Steam.getAppID(), 1)
	Steam.sendQueryUGCRequest(query_handle)
func _on_ugc_query_completed(handle, result, total_results, number_of_matching_results, cached):
	if result == 1:
		if query_handle == handle:
			for i in range(total_results):
				var data = Steam.getQueryUGCResult(handle, i)

				if data.result == 1:
					var url = Steam.getQueryUGCPreviewURL(handle, i)
					var prev_data = HBWorkshopPreviewData.new()
					var scene = THUMBNAIL_SCENE.instance()
					prev_data.preview_url = url
					prev_data.title = data.title
					print(data.title)
					grid_container.add_child(scene)
					scene.set_data(prev_data)

func select_item(item_i: int):
	grid_container.get_child(current_selected_item).stop_hover()
	
	var child = grid_container.get_child(item_i)

	current_selected_item = item_i

	if child.rect_position.y + child.rect_size.y > scroll_container.scroll_vertical + scroll_container.rect_size.y or \
			child.rect_position.y < scroll_container.scroll_vertical:
		scroll_container.scroll_vertical = child.rect_position.y
	child.hover()

func _input(event):
	
	var position_change = 0
	
	if event.is_action_pressed("gui_down"):
		position_change += grid_container.columns
	elif event.is_action_pressed("gui_up"):
		position_change -= grid_container.columns
	elif event.is_action_pressed("gui_right"):
		position_change += 1
	elif event.is_action_pressed("gui_left"):
		position_change -= 1
	if position_change != 0:
		var new_pos = current_selected_item + position_change
		new_pos = clamp(new_pos, 0, grid_container.get_child_count() - 1)
		if new_pos != current_selected_item:
			select_item(new_pos)
