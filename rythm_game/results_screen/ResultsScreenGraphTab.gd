extends TabbedContainerTab

@onready var chart_control = get_node("MarginContainer/VBoxContainer/Panel/Chart")
@onready var minimap_control = get_node("MarginContainer/VBoxContainer/Panel2/MarginContainer/Control")
var game_info: HBGameInfo

func set_game_info(_game_info: HBGameInfo):
	game_info = _game_info
	

func _enter_tab():
	var points = game_info.result._percentage_graph
	var max_y = 0
	for point in points:
		max_y = max(point.y, max_y)
	max_y = max(max_y, 100.0)
	chart_control.value_max_y = max_y
	chart_control.value_max = 100.0
	if points.size() > 0:
		chart_control.points = [Vector2(0, 0)] + points + [Vector2(100.0, points[-1].y)]
	chart_control.dots = game_info.result._combo_break_points
	minimap_control.set_game_info(game_info)
