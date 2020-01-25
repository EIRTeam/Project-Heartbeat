extends "Option.gd"

signal changed(value)

var text setget set_text

func set_value(val):
	.set_value(val)
	var res = 0
	
	if not val:
		res = 1
	$OptionSelect.select(res)
	print("SELECTING VALUE", res)
func set_text(val):
	text = val
	$OptionSelect.text = val

func _ready():
	$OptionSelect.connect("changed", self, "_on_changed")
	$OptionSelect.options = ["No", "Yes"]
func _on_changed(val):
	if val == "Yes":
		emit_signal("changed", true)
	else:
		emit_signal("changed", false)

func _gui_input(event):
	$OptionSelect._gui_input(event)
