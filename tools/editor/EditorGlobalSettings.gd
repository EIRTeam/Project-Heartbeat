extends WindowDialog

const GENERAL_OPTIONS = [
	["Automatically save when \"Play\" is pressed", "editor_autosave_enabled"]
]

onready var general_tab_tree: Tree = get_node("TabContainer/General/Tree")
onready var song_settings_tab = get_node("TabContainer/Song")

func _ready():
	connect("about_to_show", self, "_on_about_to_show")
	general_tab_tree.connect("item_edited", self, "_on_tree_item_edited")

func _on_about_to_show():
	populate_general_tab()

func populate_general_tab():
	general_tab_tree.clear()
	var root: TreeItem = general_tab_tree.create_item()
	for option in GENERAL_OPTIONS:
		var option_name = option[0]
		var option_property = option[1]
		var prop_value = UserSettings.user_settings.get(option_property)
		match typeof(prop_value):
			TYPE_BOOL:
				var item := general_tab_tree.create_item(root)
				item.set_text(0, option_name)
				item.set_meta("type", TYPE_BOOL)
				item.set_meta("property_name", option_property)
				item.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
				item.set_checked(1, prop_value)
				item.set_editable(1, true)
				item.set_text(1, "Enabled")

func _on_tree_item_edited():
	var edited := general_tab_tree.get_edited()
	var property_name := edited.get_meta("property_name") as String
	var type = edited.get_meta("type")
	match type:
		TYPE_BOOL:
			var checked := edited.is_checked(1)
			var current_value = UserSettings.user_settings.get(property_name)
			if current_value != checked:
				UserSettings.user_settings.set(property_name, checked)
				UserSettings.save_user_settings()
func _on_bool_toggled(value: bool, property_name: String):
	UserSettings.user_settings.set(property_name, value)
	UserSettings.save_user_settings()
