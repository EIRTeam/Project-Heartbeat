extends HBTimingPoint

class_name HBChartSection

var name := "New section"
var color: Color

# Nord palette jej
const palette = [
	"#81a1c1",
	"#bf616a",
	"#d08770",
	"#ebcb8b",
	"#a3be8c",
	"#b48ead",
	"#d8dee9",
]

func _init():
	_class_name = "HBChartSection" # Workaround for godot#4708
	_inheritance.append("HBTimingPoint")
	
	color = Color(palette[randi() % palette.size()])
	serializable_fields += ["name", "color"]

func get_serialized_type():
	return "ChartSection"

static func can_show_in_editor():
	return true

func get_inspector_properties():
	return HBUtils.merge_dict(super.get_inspector_properties(), {
		"name": {
			"type": "String",
			"params": {
				"default": "Section Name",
			}
		},
		"color": {
			"type": "Color",
			"params": {
				"presets": palette,
			},
		},
	})

func get_timeline_item():
	var timeline_item_scene = load("res://tools/editor/timeline_items/EditorSectionTimelineItem.tscn")
	var timeline_item = timeline_item_scene.instantiate()
	timeline_item.data = self
	return timeline_item
