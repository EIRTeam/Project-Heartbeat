extends HBMenu

class_name HBOOBMenu

signal show_text(text: String)

enum OOB_STEP_BUTTON_ACTIONS {
	SET_USER_SETTING = 1,
	GO_TO_NEXT_STEP = 2,
	END_SETUP = 4
}

class OOBStepOption:
	var actions: int
	var user_setting_name: String
	var user_setting_value: Variant
	var button_name: String
	var button_description: String
	var icon: Texture2D
	
	func _init(_button_name: String, _button_description: String):
		button_name = _button_name
		button_description = _button_description
		
	func set_user_setting(_setting_name: String, _setting_value: Variant) -> OOBStepOption:
		user_setting_name = _setting_name
		user_setting_value = _setting_value
		actions = actions | OOB_STEP_BUTTON_ACTIONS.SET_USER_SETTING
		return self
	func end_setup() -> OOBStepOption:
		actions = actions | OOB_STEP_BUTTON_ACTIONS.END_SETUP
		return self
	func next_step() -> OOBStepOption:
		actions = actions | OOB_STEP_BUTTON_ACTIONS.GO_TO_NEXT_STEP
		return self
	func with_icon(_icon: Texture2D) -> OOBStepOption:
		icon = _icon
		return self

class OOBStep:
	var step_title: String
	var step_options: Array[OOBStepOption]
	var step_description: OOBDialogue
	var step_footer: String
	func _init(_step_title: String, _step_description: OOBDialogue, _step_footer: String, _step_options: Array[OOBStepOption]):
		step_title = _step_title
		step_description = _step_description
		step_options = _step_options
		step_footer = _step_footer
		
var option_footer := tr("You can change this later at any time in the options menu.")
		
class OOBDialogue:
	var accumulated_text: String
	var tokens: Array[DialogueToken]
	var current_token := 0
	var current_time := 0.0
	
	class DialogueOut:
		var text: String
		var done: bool
	
	class DialogueToken:
		func _tick(time: float, out: DialogueOut):
			pass
	
	class DialogueTextToken:
		extends DialogueToken
		const CHARACTERS_PER_SECOND := 30
		var text: String
		func _init(_text: String) -> void:
			text = _text
		
		func _tick(time: float, out: DialogueOut):
			var characters := min(time * CHARACTERS_PER_SECOND, text.length())
			out.text = text.substr(0, characters)
			out.done = characters == text.length()
		
	class DialoguePauseToken:
		extends DialogueToken
		var pause_duration := 0.0
		func _init(_pause_duration: float) -> void:
			pause_duration = _pause_duration
		
		func _tick(time: float, out: DialogueOut):
			out.done = time >= pause_duration
		
	func text(_text: String):
		tokens.push_back(DialogueTextToken.new(_text))
		return self
	
	func pause(pause_duration := 0.5):
		tokens.push_back(DialoguePauseToken.new(pause_duration))
		return self
		
	func begin():
		accumulated_text = ""
		current_token = 0
		current_time = 0.0
	
	func is_done() -> bool:
		return current_token >= tokens.size()
	
	func _tick(delta: float) -> String:
		if is_done():
			return ""
		var out := DialogueOut.new()
		current_time += delta
		tokens[current_token]._tick(current_time, out)
		if out.done:
			current_token += 1
			accumulated_text += out.text
			current_time = 0.0
			return accumulated_text
		return accumulated_text + out.text
var oob_steps: Array[OOBStep] = [
	# First page
	OOBStep.new(
		tr("Welcome to Project Heartbeat!"),
		OOBDialogue.new() \
			.text(tr("Welcome to Project Heartbeat!")) \
			.pause() \
			.text(tr("\n\nLet's configure a few things, together!")),
		tr("A world of rhythm gaming possibilities is ahead!"),
		[
			OOBStepOption.new(tr("Continue"), tr("Let's do it!")) \
				.with_icon(preload("res://graphics/icons/score_update_arrow.svg"))\
				.next_step(),
			OOBStepOption.new(tr("Exit"), tr("I know what I'm doing, just give me the defaults")) \
				.with_icon(preload("res://graphics/icons/exit-run-big.svg"))\
				.end_setup(),
		]
	),
	# Page 2: Health system
	OOBStep.new(
		tr("Would you like to enable health?"),
		OOBDialogue.new().text(tr("If you are in for a bigger challenge you can enable the health system!")),
		option_footer,
		[
			OOBStepOption.new(tr("No"), tr("No matter how many notes you fail the game will never end!")) \
				.set_user_setting("health_system_enabled", false) \
				.with_icon(preload("res://graphics/oob/health_off.png")) \
				.next_step(),
			OOBStepOption.new(tr("Yes"), tr("After failing to hit a bunch of notes, the game will be over.\nNote:This has not effect on scoring and its just an extra challenge.")) \
				.set_user_setting("health_system_enabled", true) \
				.with_icon(preload("res://graphics/oob/health_on.png")) \
				.next_step(),
		]
	),
	# Page 3: Note icons
	OOBStep.new(
		tr("Which note icons do you want to see?"),
		OOBDialogue.new()\
			.text(tr("Finally, you can choose note icons!")),
		"Tip: You can find more note icon packs on the Steam Workshop!\nYou can also change them at any time from the options menu, under \"Resource Packs\"",
		[
			OOBStepOption.new("Playstation™", "") \
				.set_user_setting("resource_pack", "playstation") \
				.with_icon(preload("res://graphics/resource_packs/playstation/icon.png")) \
				.next_step(),
			OOBStepOption.new("Steam Deck™/Xbox™", "") \
				.set_user_setting("resource_pack", "xbox") \
				.with_icon(preload("res://graphics/resource_packs/xbox/icon.png")) \
				.next_step(),
			OOBStepOption.new("Nintendo™", "") \
				.set_user_setting("resource_pack", "nintendo") \
				.with_icon(preload("res://graphics/resource_packs/nintendo/icon.png")) \
				.next_step(),
		]
	),
	# Page 4: Done!
	OOBStep.new(
		tr("You're ready!"),
		OOBDialogue.new().text(tr("You are now ready to play Project Heartbeat!")),
		"""Remember: Project Heartbeat is still in Early Access!

Be sure to join the discord to report bugs or to give suggestions on how to improve it!
You can also follow the official Twitter/X account: @PHeartbeatGame

And more importantly: Have fun!""",
		[
			OOBStepOption.new("Let's go!", "") \
				.end_setup()
		]
	)
]

@onready var title_label: Label = get_node("%TitleLabel")
@onready var button_container: HBSimpleMenu = get_node("%ButtonContainer")
@onready var button_description_label: Label = get_node("%ButtonDescriptionLabel")
@onready var step_footer_label: Label = get_node("%StepFooterLabel")

var current_step := 0

func _setup_step_button(step_option: OOBStepOption) -> HBHovereableButton:
	var button := HBHovereableButton.new()
	button.text = step_option.button_name
	button.hovered.connect(self._on_display_description.bind(step_option.button_description))
	if step_option.actions & OOB_STEP_BUTTON_ACTIONS.GO_TO_NEXT_STEP:
		button.pressed.connect(self.advance_to_next_step)
	if step_option.actions & OOB_STEP_BUTTON_ACTIONS.END_SETUP:
		button.pressed.connect(self.end_setup)
	if step_option.actions & OOB_STEP_BUTTON_ACTIONS.SET_USER_SETTING:
		print("SETTING USER SETTING", step_option.user_setting_name, step_option.user_setting_value)
		button.pressed.connect(self._set_user_setting.bind(step_option.user_setting_name, step_option.user_setting_value))
	button.icon = step_option.icon
	if button.icon:
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.update_minimum_size()
	return button
	
func _set_user_setting(user_setting_name: String, user_setting_value: Variant):
	UserSettings.user_settings.set(user_setting_name, user_setting_value)
	UserSettings.save_user_settings()
	
func end_setup():
	change_to_menu("main_menu")
	UserSettings.user_settings.oob_completed = true
	UserSettings.save_user_settings()
	
func _on_display_description(description: String):
	button_description_label.show()
	button_description_label.text = description
	if button_description_label.text.is_empty():
		button_description_label.hide()

func advance_to_next_step():
	go_to_step(current_step+1)

func go_to_step(step: int):
	assert(step < oob_steps.size())
	current_step = step
	var step_data := oob_steps[step]
	
	show_text.emit("")
	
	for child in button_container.get_children():
		button_container.remove_child(child)
		child.queue_free()
	
	for step_option in step_data.step_options:
		var button := _setup_step_button(step_option)
		var container := AspectRatioContainer.new()
		button_container.add_child(button)
	button_container.grab_focus()
	step_footer_label.text = step_data.step_footer
	step_data.step_description.begin()
	title_label.text = step_data.step_title
	button_description_label.text = ""
	await get_tree().process_frame
	button_container.select_button(0)
	
func _process(delta: float):
	var step_data := oob_steps[current_step]
	
	if not step_data.step_description.is_done():
		show_text.emit(step_data.step_description._tick(delta))
	
func _on_menu_enter(force_hard_transition=false, args = {}):
	super._on_menu_enter(force_hard_transition, args)
	
	go_to_step(0)
	
