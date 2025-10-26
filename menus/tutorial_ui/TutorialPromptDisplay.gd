extends HBoxContainer

class_name HBTutorialUIPromptDisplay

func _ready() -> void:
	#container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#for i in range(4):
		#var cr := InputGlyphRect.new()
		#cr.action_name = ["note_up", "note_right", "note_down", "note_left"][i]
		#cr.action_text = ""
		#cr.expand_texture = true
		#cr.custom_minimum_size = Vector2(64, 64)
		#container.add_child(cr)
	show_prompts([&"note_up", &"note_right", &"note_down", &"note_left"], true)
func clear():
	for child in get_children():
		remove_child(child)
		child.queue_free()

func fill_prompt_container(container: HBRadialContainer, prompts: Array[StringName], action_offset := 0):
	for i in range(prompts.size()):
		var prompt := prompts[i]
		var cr := InputGlyphRect.new()
		cr.action_name = prompt
		cr.action_text = ""
		cr.expand_texture = true
		#cr.add_theme_font_size_override(&"fallback_glyph_font_size", 32)
		cr.custom_minimum_size = Vector2(72, 72)
		cr.action_skip_count = action_offset
		container.add_child(cr)

func show_prompts(prompts: Array[StringName], double := false):
	var prompt_container_one := HBRadialContainer.new()
	prompt_container_one.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prompt_container_one.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var group_size := get_theme_constant(&"prompt_group_size", &"HBTutorialUIPromptDisplay")
	prompt_container_one.custom_minimum_size = Vector2(group_size, group_size)
	add_child(prompt_container_one)
	fill_prompt_container(prompt_container_one, prompts)
	
	if double:
		var prompt_container_two := HBRadialContainer.new()
		prompt_container_two.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		prompt_container_two.size_flags_vertical = Control.SIZE_EXPAND_FILL
		prompt_container_two.custom_minimum_size = Vector2(group_size, group_size)
		add_child(prompt_container_two)
		fill_prompt_container(prompt_container_two, prompts, 1)
		
