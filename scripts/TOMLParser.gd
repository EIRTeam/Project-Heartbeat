class_name TOMLParser

static func parse(contents: String) -> Dictionary:
	var out := {"default": {}}
	
	var lines := contents.split("\n")
	var current_section := "default"
	for line in lines:
		if line.begins_with("["):
			var section := line.substr(1, line.length()-2) as String
			out[section] = {}
			current_section = section
			continue
		var line_split = line.split("=") as PackedStringArray
		if line_split.size() > 1:
			var line_key := line_split[0].strip_edges() as String
			var line_value := line_split[1].strip_edges() as String
			if line_value.begins_with("\"") and line_value.ends_with("\""):
				out[current_section][line_key] = line_value.substr(1, line_value.length()-2)
			elif line_value == "true":
				out[current_section][line_key] = true
			elif line_value == "false":
				out[current_section][line_key] = false
			elif line_value.is_valid_int():
				out[current_section][line_key] = line_value.to_int()
			elif line_value.is_valid_float():
				out[current_section][line_key] = line_value.to_float()
	return out

static func from_file(path: String) -> Dictionary:
	var contents := ""

	var f := FileAccess.open(path, FileAccess.READ)
	if FileAccess.get_open_error() == OK:
		contents = f.get_as_text()
	return parse(contents)
		
