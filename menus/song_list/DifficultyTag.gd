extends PanelContainer

class_name HBDifficultyTag

@onready var difficulty_color_panel: Control = get_node("%DifficultyColorPanel")
@onready var difficulty_label: Label = get_node("%DifficultyLabel")
@onready var star_label: Label = get_node("%StarLabel")
@onready var border_container: PanelContainer = get_node("%SelectionBorderContainer")
@onready var background_stylebox: StyleBox
@onready var inner_stylebox: StyleBox
@onready var selection_border_stylebox: StyleBox

const VALUE := 0.75
const SATURATION := 0.7

var hovering := false

var CANONICAL_COLORS := {
	"easy": Color.from_hsv(190/360.0, SATURATION, VALUE),
	"normal": Color.from_hsv(111/360.0, SATURATION, VALUE),
	"hard": Color.from_hsv(46/360.0, SATURATION, VALUE),
	"extreme": Color.from_hsv(343/360.0, SATURATION, VALUE),
}

signal pressed
signal hovered

func color_hash(str: String) -> Color:
	var hash_ctx := HashingContext.new()
	hash_ctx.start(HashingContext.HASH_SHA256)
	hash_ctx.update(str.to_utf8_buffer())
	var hashed := hash_ctx.finish()
	
	var str_hash := hashed.decode_u32(0)
	var hash1 = str_hash & 0xFF
	var hash2 = (str_hash & 0xFF00) >> 8
	var hash3 = (str_hash & 0xFF0000) >> 16
	return Color(hash1/float(0xFF), hash2/float(0xFF), hash3/float(0xFF), 1.0)

var tag_update_queued := false 

func _queue_tag_update():
	if not tag_update_queued:
		tag_update_queued = true
		if not is_node_ready():
			await ready
		_tag_update.call_deferred()

func _tag_update():
	if tag_update_queued:
		tag_update_queued = false
		difficulty_label.text = difficulty
		if difficulty in CANONICAL_COLORS:
			difficulty_color_panel.self_modulate = CANONICAL_COLORS[difficulty]
			difficulty_color_panel.self_modulate.a = 1.0
		else:
			difficulty_color_panel.self_modulate = color_hash(difficulty)
			
		if fmod(stars, floor(stars)) != 0:
			star_label.text = "%.1f" % [stars]
		else:
			star_label.text = "%d" % [stars]

var difficulty: String:
	set(val):
		difficulty = val
		_queue_tag_update()

var stars: float:
	set(val):
		stars = val
		_queue_tag_update()

func _draw() -> void:
	
	background_stylebox.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
	inner_stylebox.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
	if hovering:
		selection_border_stylebox.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
		draw_rect(Rect2(Vector2.ZERO, size), Color.BLUE, false)

func _process(delta: float) -> void:
	var alpha_target := sin((Time.get_ticks_msec()/1000.0) * PI / 1.0) / 2.0 + 0.5
	alpha_target *= 0.75
	alpha_target += 0.25
	_update_alpha(alpha_target)

func _update_alpha(alpha: float):
	self_modulate.a = alpha
	difficulty_color_panel.self_modulate.a = alpha

func _ready() -> void:
	set_process(false)
	selection_border_stylebox = get_theme_stylebox("panel_selection", &"DifficultyTag")
	inner_stylebox = get_theme_stylebox("panel_inner", &"DifficultyTag")
	background_stylebox = get_theme_stylebox("panel_background", &"DifficultyTag")
	add_theme_stylebox_override("panel", background_stylebox)
	difficulty_color_panel.add_theme_stylebox_override("panel", inner_stylebox)
	border_container.add_theme_stylebox_override("panel", selection_border_stylebox)
	border_container.hide()

func hover():
	hovering = true
	queue_redraw()
	hovered.emit()
	border_container.show()
	set_process(true)

func stop_hover():
	hovering = false
	queue_redraw()
	border_container.hide()
	set_process(false)
	_update_alpha(1.0)
