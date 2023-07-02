# PPD-style ini parser, it supports spaces where ConfigFile doesn't
class_name HBINIParser

static func parse(contents: String) -> Dictionary:
	var dict = {}
	var current_section = ""
	for line in contents.split('\n'):
		line = line.strip_edges()
		if line.begins_with("[") and line.ends_with("]"):
			current_section = line.substr(1, line.length()-2)
			dict[current_section] = {}
		else:
			var vk_pair = line.split('=')
			var value = null
			if vk_pair.size() > 1:
				value = vk_pair[1]
			dict[current_section][vk_pair[0]] = value
	return dict
