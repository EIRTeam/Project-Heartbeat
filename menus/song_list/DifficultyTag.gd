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

var difficulty_color: Color
var difficulty_color_bright: Color

var tag_update_queued := false

var filtered := false

const FILTERED_COLOR = Color.DARK_GRAY
const FILTERED_COLOR_BG = Color.DIM_GRAY

func _queue_tag_update():
	if not tag_update_queued:
		tag_update_queued = true
		if not is_node_ready():
			await ready
		_tag_update.call_deferred()

func _update_tag_color():
	if UserSettings.user_settings.sort_filter_settings.star_filter_enabled:
		if stars > UserSettings.user_settings.sort_filter_settings.star_filter_max:
			difficulty_color_panel.self_modulate = FILTERED_COLOR
			self_modulate = FILTERED_COLOR_BG
			modulate.a = 0.5
			filtered = true
			return
		
	if difficulty in CANONICAL_COLORS:
		difficulty_color_panel.self_modulate = CANONICAL_COLORS[difficulty]
	else:
		difficulty_color_panel.self_modulate = color_hash(difficulty)

func _tag_update():
	if tag_update_queued:
		tag_update_queued = false
		difficulty_label.text = difficulty
		_update_tag_color()
		difficulty_color = difficulty_color_panel.self_modulate
		difficulty_color_bright = difficulty_color.lightened(0.5)
			
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

func _process(delta: float) -> void:
	var alpha_target := sin((Time.get_ticks_msec()/1000.0) * PI / 1.0) / 2.0 + 0.5
	alpha_target *= 0.75
	alpha_target += 0.25
	_update_alpha(alpha_target)

func _update_alpha(alpha: float):
	difficulty_color_panel.self_modulate = difficulty_color.lerp(difficulty_color_bright, alpha)

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
	hovered.emit()
	border_container.show()
	set_process(true)
	if filtered:
		modulate.a = 1.0

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER_SELF:
			hover()
		NOTIFICATION_MOUSE_EXIT_SELF:
			stop_hover()

func stop_hover():
	hovering = false
	border_container.hide()
	set_process(false)
	_update_alpha(0.0)
	if filtered:
		modulate.a = 0.5
