class_name TOMLParser
## A parser for a subset of TOML.
## 
## As of now it only needs to support strings, booleans, ints, floats and arrays
## to properly parse mods. This could change in the future.
## It also does not support all key types: Only bare and dot keys will be parsed correctly.

## Parse a TOML string. Dot keys are only supported in table or array definitions.
static func parse(contents: String) -> Dictionary:
	var out := {"default": {}}
	
	var output_ref = out["default"]
	
	var lines := contents.split("\n")
	for line in lines:
		# Array of tables
		if line.begins_with("[["):
			var key := line.substr(2, line.length()-5) as String
			var new_sections = parse_key(key)
			var array_key = new_sections.pop_back()
			
			if not array_key:
				continue
			
			# Build inner representation of the object from the key data and get
			# an output reference to the parent table
			output_ref = out
			for section in new_sections:
				if output_ref.has(section):
					var new_ref = output_ref[section]
					
					if new_ref is Array and not new_ref.is_empty():
						# Set section to last defined object of this array
						output_ref = new_ref[-1]
					else:
						# Set section
						output_ref = new_ref
				else:
					output_ref[section] = {}
			
			# Create array if it doesnt exist
			if not output_ref.has(array_key):
				output_ref[array_key] = []
			
			# Create a new entry in the table and set the output reference
			output_ref[array_key].push_back({})
			output_ref = output_ref[array_key][-1]
			
			continue
		
		# Tables/sections
		if line.begins_with("["):
			var key := line.substr(1, line.length()-2) as String
			var new_sections = parse_key(key)
			var table_key = new_sections.pop_back()
			
			if not table_key:
				continue
			
			# Build inner representation of the object from the key data and get
			# an output reference to the parent table
			output_ref = out
			for section in new_sections:
				if output_ref.has(section):
					var new_ref = output_ref[section]
					
					if new_ref is Array:
						# Set section to last defined object of this array
						output_ref = new_ref[-1]
					else:
						# Set section
						output_ref = new_ref
				else:
					output_ref[section] = {}
			
			output_ref[table_key] = {}
			output_ref = output_ref[table_key]
			
			continue
		
		var line_split = line.split("=") as PackedStringArray
		if line_split.size() > 1:
			var line_key := line_split[0].strip_edges() as String
			var line_value := line_split[1].strip_edges() as String
			
			var output = null
			
			if line_value.begins_with("\"") and line_value.ends_with("\""):
				output = line_value.substr(1, line_value.length()-2)
			elif line_value == "true":
				output = true
			elif line_value == "false":
				output = false
			elif line_value.is_valid_int():
				output = line_value.to_int()
			elif line_value.is_valid_float():
				output = line_value.to_float()
			
			if output != null:
				output_ref[line_key] = output
	
	return out

## Parse an arbitrary key. Currently this only supports bare keys and dot keys
## See https://toml.io/en/v1.0.0#keys for more information.
## 
## Returns keys in an ordered array based on depth (a.b.c => ["a", "b", "c"]).
static func parse_key(key: String) -> Array:
	return key.split(".")

## Load and parse a TOML file.
static func from_file(path: String) -> Dictionary:
	var contents := ""

	var f := FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() == OK:
		contents = f.get_as_text()
	return parse(contents)
		
