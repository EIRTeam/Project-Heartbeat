tool
extends HBEditorWidget
signal note_moved(new_pos)
signal note_moving_finished()
onready var movement_gizmo = get_node("MovementGizmo")

var internal_pos : Vector2
var starting_pos

func _ready():
	arrange_gizmo()
	get_viewport().connect("size_changed", self, "_on_resized")
	
func _on_resized():
	yield(get_tree(), "idle_frame")
	arrange_gizmo()
	
func arrange_gizmo():
	var note_scale = editor.rhythm_game.get_note_scale()
	movement_gizmo.rect_size = Vector2(128, 128) * note_scale
	movement_gizmo.rect_position = rect_size / 2 - movement_gizmo.rect_size/2
	internal_pos = rect_position
	
func _on_dragged(movement: Vector2):
	internal_pos += movement
	emit_signal("note_moved", internal_pos)
	var snapped_pos = editor.snap_position_to_grid(editor.rhythm_game.inv_map_coords(internal_pos + rect_size/2))
	rect_position = editor.rhythm_game.remap_coords(snapped_pos) - rect_size / 2


func _on_start_dragging():
	internal_pos = rect_position

func _on_finish_dragging():
	emit_signal("note_moving_finished")
