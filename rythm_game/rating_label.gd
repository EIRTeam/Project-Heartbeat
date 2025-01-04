extends Control

class_name HBJudgementLabel

const DISAPPEAR_TIMEOUT = 1.0
const DISAPPEAR_TIME = 0.1
var disappear_timeout_t = 0.0
var disappear_time_t = 0.0

var WRONG_JUDGEMENT_TEXTURES: Array[AtlasTexture]
var JUDGEMENT_TEXTURES: Array[AtlasTexture]
var COMBO_NUMBER_TEXTURES: Array[AtlasTexture]
var wrong_rating_cross: Texture2D = preload("res://graphics/wrong_rating_cross.png")

var tween: Tween

var current_judgement_tex: AtlasTexture
var current_combo: int
var judgement_wrong: bool
var combo_color: Color

const JUDGEMENT_HEIGHT = 80
const WRONG_CROSS_HEIGHT := 48
const JUDGEMENT_TO_COMBO_MARGIN := 7

func _ready() -> void:
	texture_filter = TextureFilter.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	for judgement: String in HBJudge.JUDGE_RATINGS:
		var graphic_name := judgement.to_lower() + ".png"
		JUDGEMENT_TEXTURES.push_back(ResourcePackLoader.get_graphic(graphic_name))
		if judgement == "WORST":
			# HACK: Empty atlas texture for this one...
			WRONG_JUDGEMENT_TEXTURES.push_back(ResourcePackLoader.get_graphic("wrong.png"))
		else:
			var wrong_graphic_name := judgement.to_lower() + "_wrong" + ".png"
			WRONG_JUDGEMENT_TEXTURES.push_back(ResourcePackLoader.get_graphic(wrong_graphic_name))
	for i in range(10):
		COMBO_NUMBER_TEXTURES.push_back(ResourcePackLoader.get_graphic("combo_%d.png" % i))

func fit_texture_in_height(texture: AtlasTexture, height: float) -> Vector2:
	var tex_size := texture.get_size()
	var ratio := tex_size.x / tex_size.y
	var final_size := Vector2(height * ratio, height)
	return final_size

func get_real_texture_rect(texture: AtlasTexture, draw_rect: Rect2) -> Rect2:
	var tex_size := texture.get_size()
	var tex_scale := (draw_rect.size.y / tex_size.y)
	var t := draw_rect.position + texture.margin.position * tex_scale
	return Rect2(t, texture.region.size * tex_scale)

const RATING_TO_COLOR = {
	HBJudge.JUDGE_RATINGS.COOL: Color("#ffd022"),
	HBJudge.JUDGE_RATINGS.FINE: Color("#4ebeff"),
	HBJudge.JUDGE_RATINGS.SAFE: Color("#00a13c"),
	HBJudge.JUDGE_RATINGS.SAD: Color("#57a9ff"),
	HBJudge.JUDGE_RATINGS.WORST: Color("#e470ff")
}

func _draw():
	if current_judgement_tex:
		var center := size * 0.5
		var judgement_tex_size := current_judgement_tex.get_size()
		
		var judgement_size := fit_texture_in_height(current_judgement_tex, JUDGEMENT_HEIGHT)
		
		var judgement_tex_pos := center - (judgement_size*0.5)
		
		var judgement_tex_draw_rect := Rect2(judgement_tex_pos, judgement_size)
		current_judgement_tex.draw_rect(get_canvas_item(), judgement_tex_draw_rect, false)
		#draw_circle(Vector2.ZERO, 5.0, Color.RED)
		
		var judgement_tex_real_rect := get_real_texture_rect(current_judgement_tex, judgement_tex_draw_rect)
		var judgement_size_real := judgement_tex_real_rect.size
		
		# Draw combo number
		if current_combo > 0:
			var combo_pos := Vector2.ZERO
			combo_pos = center
			combo_pos.x += judgement_tex_real_rect.position.x + judgement_size_real.x
			combo_pos.y -= JUDGEMENT_HEIGHT * 0.5
			combo_pos.x += JUDGEMENT_TO_COMBO_MARGIN
			
			var combo_str := str(current_combo)
			for c in combo_str:
				var combo_number_texture := COMBO_NUMBER_TEXTURES[int(c)]
				var combo_tex_size := fit_texture_in_height(combo_number_texture, JUDGEMENT_HEIGHT)
				combo_pos.x -= 35
				var combo_texture_rect := Rect2(combo_pos, combo_tex_size)
				var real_combo_texture_rect := get_real_texture_rect(combo_number_texture, combo_texture_rect)
				combo_pos.x = real_combo_texture_rect.position.x + real_combo_texture_rect.size.x
				#draw_rect(combo_texture_rect, Color.BLUE, false)
				#draw_rect(real_combo_texture_rect, Color.BLUE, false)
				combo_number_texture.draw_rect(get_canvas_item(), combo_texture_rect, false, combo_color.lightened(0.7))
		
		if judgement_wrong:
			var wrong_rating_position := center
			wrong_rating_position.x += judgement_size_real.x * 0.5
			wrong_rating_position.y -= WRONG_CROSS_HEIGHT * 0.5
			
			var wrong_cross_ratio := wrong_rating_cross.get_size().x / wrong_rating_cross.get_size().y
			var wrong_cross_size := Vector2(WRONG_CROSS_HEIGHT*wrong_cross_ratio, WRONG_CROSS_HEIGHT)
			
			wrong_rating_cross.draw_rect(get_canvas_item(), Rect2(wrong_rating_position, wrong_cross_size), false)
		#draw_rect(Rect2(judgement_tex_pos, judgement_size), Color.BLUE, false)
		#draw_rect(Rect2(judgement_pos_real-judgement_size_real*0.5, judgement_size_real), Color.GREEN, false)
		#draw_circle(wrong_rating_position, 5.0, Color.REBECCA_PURPLE)

func show_judgement(new_position: Vector2, judgement: HBJudge.JUDGE_RATINGS, wrong: bool, combo: int):
	if tween:
		tween.kill()
		tween = null
	modulate.a = 1.0
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.1) \
		.set_delay(1.0)
	if wrong:
		current_judgement_tex = WRONG_JUDGEMENT_TEXTURES[judgement]
	else:
		current_judgement_tex = JUDGEMENT_TEXTURES[judgement]
	position = new_position
	size = Vector2.ZERO
	queue_redraw()
	if (position.y - JUDGEMENT_HEIGHT * 0.5) > ResourcePackLoader.current_skin.rating_label_top_margin:
		position.y -= JUDGEMENT_HEIGHT
	else:
		position.y += JUDGEMENT_HEIGHT
	judgement_wrong = wrong
	current_combo = combo
	combo_color = RATING_TO_COLOR[judgement]
	#current_judgement_tex = JUDGEMENT_TEXTURES[judgement]
	#if worst:
		#var center := size * 0.5
		#var cross_position := center
		#cross_position.x += JUDGEMENT_TEXTURES[judgement].region.size.x
		#wrong_rating_cross.position = cross_position
		#wrong_rating_cross.size.y = size.y
		#wrong_rating_cross.size.x = size.y
