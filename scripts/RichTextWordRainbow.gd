@tool
extends RichTextEffect
class_name RichTextWordRainbow

var bbcode = "word_rainbow"

func _process_custom_fx(char_fx):
	var freq = char_fx.env.get("freq", 1.0)
	var saturation = char_fx.env.get("saturation", 0.8)
	var value = char_fx.env.get("value", 0.8)
	
	var color = Color.from_hsv(freq * char_fx.elapsed_time, saturation, value, char_fx.color.a)
	
	char_fx.color = color
	return true
