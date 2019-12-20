tool
extends HBEditorWidget
signal note_moved(new_pos)
signal note_moving_finished()
onready var y_axis_arrow = get_node("YAxisArrow")
onready var x_axis_arrow = get_node("XAxisArrow")
onready var round_movement_gizmo = get_node("RoundMovementGizmo")

var internal_pos : Vector2
var starting_pos

func _ready():
	arrange_arrows()
	internal_pos = rect_position
	

func arrange_arrows():
	x_axis_arrow.rect_position.x = rect_size.x/2
	x_axis_arrow.rect_position.y = rect_size.y/2 - x_axis_arrow.rect_size.y / 2
	
	y_axis_arrow.rect_position.x = rect_size.x/2 - y_axis_arrow.rect_size.x / 2
	y_axis_arrow.rect_position.y = 0

	round_movement_gizmo.rect_position = rect_size / 2 - round_movement_gizmo.rect_size/2

func _on_dragged(movement: Vector2):
	internal_pos += movement
	emit_signal("note_moved", internal_pos)
	var snapped_pos = editor.snap_position_to_grid(editor.rhythm_game.inv_map_coords(internal_pos + rect_size/2))
	rect_position = editor.rhythm_game.remap_coords(snapped_pos) - rect_size / 2
func _on_XAxisArrow_dragged(relative_movement: Vector2):
	_on_dragged(Vector2(relative_movement.x, 0))

func _on_YAxisArrow_dragged(relative_movement: Vector2):
	_on_dragged(Vector2(0, relative_movement.y))


func _on_start_dragging():
	internal_pos = rect_position


func _on_finish_dragging():
	emit_signal("note_moving_finished")
