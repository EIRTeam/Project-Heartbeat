extends Panel

var package_meta: HBPackageMeta setget set_package

signal package_meta_saved

onready var name_edit = get_node("TabContainer/Package Info/PackageName")
onready var version_edit = get_node("TabContainer/Package Info/PackageVersion")
onready var description_edit = get_node("TabContainer/Package Info/PackageDescription")
onready var authors_edit = get_node("TabContainer/Package Info/PackageAuthors")

func set_package(value):
	package_meta = value
	name_edit.text = package_meta.name
	version_edit.text = package_meta.version
	
	authors_edit.text = PoolStringArray(package_meta.authors).join("\n")
	
	description_edit.text = package_meta.description

func _ready():
	pass


func _on_SaveButton_pressed():
	package_meta.name = name_edit.text
	package_meta.version = version_edit.text
	package_meta.description = description_edit.text
	package_meta.authors = Array(authors_edit.text.split("\n"))
	emit_signal("package_meta_saved")
