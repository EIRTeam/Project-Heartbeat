extends "Option.gd"

signal changed(value)

var text setget set_text

func set_value(val):
	.set_value(val)
	var res = 0
	var result = $OptionSelect.options.find(val)
	if result != -1:
		res = result
	$OptionSelect.select(res)
	print("SELECTING VALUE", res)
	
func set_text(val):
	text = val
	$OptionSelect.text = val

func _ready():
	$OptionSelect.connect("changed", self, "_on_changed")
	var options = []
	var pretty_options = []
	for pack_name in IconPackLoader.packs:
		var pack = IconPackLoader.packs[pack_name]
		options.append(pack_name)
		pretty_options.append(pack.name)
	$OptionSelect.options = options
	$OptionSelect.options_pretty = pretty_options
func _on_changed(val):
	emit_signal("changed", val)

func _gui_input(event):
	$OptionSelect._gui_input(event)
