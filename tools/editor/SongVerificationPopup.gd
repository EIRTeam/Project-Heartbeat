extends AcceptDialog

@onready var tab_container = get_node("TabContainer")

func show_song_verification(errors, for_ugc=true, text=""):
	popup_centered_ratio(0.5)
	
	var error_c = 0
	for error_class in errors:
		error_c += errors[error_class].size()
	for child in tab_container.get_children():
		tab_container.remove_child(child)
		child.queue_free()
	if error_c == 0:
		tab_container.hide()
		self.dialog_text = "No errors were found"
	else:
		self.dialog_text = text
		tab_container.show()
		for error_class in errors:
			if errors[error_class].size() > 0:
				var scroll_container = ScrollContainer.new()
				if error_class.begins_with("chart_"):
					scroll_container.name = "Chart: " + error_class.trim_prefix("chart_").capitalize()
				elif error_class == "meta":
					scroll_container.name = "Song"
				else:
					scroll_container.name = error_class.capitalize()
				tab_container.add_child(scroll_container)
				var rich_text_label = RichTextLabel.new()
				rich_text_label.bbcode_enabled = true
				rich_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				rich_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
				scroll_container.add_child(rich_text_label)
				for error in errors[error_class]:
					var color = "#FFFFFF"
					var error_type = ""
					if for_ugc and error.fatal_ugc:
						error_type = "[u]FATAL (Workshop)[/u]"
						color = "#FF5555"
					elif error.fatal:
						error_type = "[u]FATAL[/u]"
						color = "#FF5555"
					elif error.warning:
						error_type = "[u]WARNING[/u]"
						color = "#FFFF00"
					rich_text_label.text += "[color=%s]%s: %s[/color]\n\n" % [color, error_type, error.string]
			
