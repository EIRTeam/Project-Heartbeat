extends TabbedContainerTab

onready var chart_control = get_node("MarginContainer/Panel/Chart")

var game_info: HBGameInfo

func set_game_info(_game_info: HBGameInfo):
	game_info = _game_info

func _enter_tab():
	var points = game_info.result._percentage_graph
	var max_y = 0
	var max_x = 0
	for point in points:
		max_y = max(point.y, max_y)
		max_x = max(point.x, max_x)
	max_y = max(max_y, 100.0)
	chart_control.value_max_y = max_y
	chart_control.value_max = max_x
	chart_control.points = points
