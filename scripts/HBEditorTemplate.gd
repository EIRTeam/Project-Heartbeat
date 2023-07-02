extends HBSerializable

class_name HBEditorTemplate

const EDITOR_TEMPLATES_PATH := "user://editor_templates"

var name := "New Template"
var filename := "new_template.json" # Internal, not serialized

var saved_properties := []
var autohide := false

# Ugly hack to get clean de/serialization
# Im sorry, me
var up_template: HBBaseNote
var down_template: HBBaseNote
var left_template: HBBaseNote
var right_template: HBBaseNote
var slide_left_template: HBBaseNote
var slide_right_template: HBBaseNote
var slide_chain_left_template: HBBaseNote
var slide_chain_right_template: HBBaseNote
var slide_left_2_template: HBBaseNote
var slide_right_2_template: HBBaseNote
var slide_chain_left_2_template: HBBaseNote
var slide_chain_right_2_template: HBBaseNote
var heart_template: HBBaseNote

func _init():
	serializable_fields += [
		"name", "saved_properties", "autohide",
		"up_template", "down_template", "left_template", "right_template", 
		"slide_left_template", "slide_right_template", "slide_chain_left_template", "slide_chain_right_template", 
		"slide_left_2_template", "slide_right_2_template", "slide_chain_left_2_template", "slide_chain_right_2_template", 
		"heart_template",
	]

func get_serialized_type() -> String:
	return "EditorTemplate"

func save(base_path: String = EDITOR_TEMPLATES_PATH) -> int:
	self.filename = HBUtils.get_valid_filename(self.name.to_lower()) + ".json"
	if self.filename == ".json":
		return ERR_FILE_BAD_PATH
	
	var path := HBUtils.join_path(base_path, filename)
	
	if FileAccess.file_exists(path):
		return ERR_ALREADY_EXISTS
	
	var file := FileAccess.open(path, FileAccess.WRITE)

	var result = FileAccess.get_open_error()
	if result != OK:
		return result
	
	var data = self.serialize()
	if not data:
		Log.log(self, "Data was not serialized.", Log.LogLevel.ERROR)
		return ERR_FILE_CORRUPT
	
	var json = JSON.stringify(data, "  ")
	if not json:
		Log.log(self, "Data could not be formatted as json.", Log.LogLevel.ERROR)
		return ERR_FILE_CORRUPT
	
	file.store_string(json)
	file.close()
	
	return OK


func _get_template(note_type: int, second_layer: bool) -> HBBaseNote:
	# Sigh
	match note_type:
		HBBaseNote.NOTE_TYPE.UP:
			return self.up_template
		HBBaseNote.NOTE_TYPE.DOWN:
			return self.down_template
		HBBaseNote.NOTE_TYPE.LEFT:
			return self.left_template
		HBBaseNote.NOTE_TYPE.RIGHT:
			return self.right_template
		HBBaseNote.NOTE_TYPE.SLIDE_LEFT:
			if not second_layer:
				return self.slide_left_template
			else:
				return self.slide_left_2_template
		HBBaseNote.NOTE_TYPE.SLIDE_RIGHT:
			if not second_layer:
				return self.slide_right_template
			else:
				return self.slide_right_2_template
		HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT:
			if not second_layer:
				return self.slide_chain_left_template
			else:
				return self.slide_chain_left_2_template
		HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT:
			if not second_layer:
				return self.slide_chain_right_template
			else:
				return self.slide_chain_right_2_template
		HBBaseNote.NOTE_TYPE.HEART:
			return self.heart_template
		_:
			return null

func has_type_template(note_type: int, second_layer: bool = false) -> bool:
	if note_type in [
						HBNoteData.NOTE_TYPE.UP,
						HBNoteData.NOTE_TYPE.DOWN,
						HBNoteData.NOTE_TYPE.LEFT,
						HBNoteData.NOTE_TYPE.RIGHT,
						HBNoteData.NOTE_TYPE.HEART
					] and second_layer:
		return false
	
	return _get_template(note_type, second_layer) != null

func get_type_template(note_type: int, second_layer: bool = false) -> Dictionary:
	var note_data := _get_template(note_type, second_layer)
	
	var template := {}
	for property in saved_properties:
		template[property] = note_data.get(property)
	
	return template

func set_type_template(note_data: HBBaseNote):
	# Sigh
	match note_data.note_type:
		HBBaseNote.NOTE_TYPE.UP:
			self.up_template = note_data
		HBBaseNote.NOTE_TYPE.DOWN:
			self.down_template = note_data
		HBBaseNote.NOTE_TYPE.LEFT:
			self.left_template = note_data
		HBBaseNote.NOTE_TYPE.RIGHT:
			self.right_template = note_data
		HBBaseNote.NOTE_TYPE.SLIDE_LEFT:
			if not note_data.get_meta("second_layer", false):
				self.slide_left_template = note_data
			else:
				self.slide_left_2_template = note_data
		HBBaseNote.NOTE_TYPE.SLIDE_RIGHT:
			if not note_data.get_meta("second_layer", false):
				self.slide_right_template = note_data
			else:
				self.slide_right_2_template = note_data
		HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT:
			if not note_data.get_meta("second_layer", false):
				self.slide_chain_left_template = note_data
			else:
				self.slide_chain_left_2_template = note_data
		HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT:
			if not note_data.get_meta("second_layer", false):
				self.slide_chain_right_template = note_data
			else:
				self.slide_chain_right_2_template = note_data
		HBBaseNote.NOTE_TYPE.HEART:
			self.heart_template = note_data
		_:
			Log.log(self, "Invalid note type for type template: " + str(note_data.note_type))

func get_transform() -> EditorTransformationTemplate:
	var transform := EditorTransformationTemplate.new()
	transform.template = self
	
	return transform

# WARNING: FOOTGUN AHEAD
# Make sure the types array is populated with dictionaries of the type 
# {type: HBBaseNote.NOTE_TYPE, second_layer: bool}
# Also, remember that DICTIONARY EQUALITY IS A LIE, you have to use hash
# THIS ALSO APPLIES TO THE IN OPERATOR, so remember to loop manually
# - Lino, 22/04/23
func are_types_valid(types: Array) -> bool:
	if not types:
		return false
	
	for is_second_layer in [true, false]:
		for type in HBBaseNote.NOTE_TYPE.values():
			var type_in_types := false
			for t in types:
				if {"type": type, "second_layer": is_second_layer}.hash() == t.hash():
					type_in_types = true
					
					break
			
			if has_type_template(type, is_second_layer) != type_in_types:
				return false
	
	return true
