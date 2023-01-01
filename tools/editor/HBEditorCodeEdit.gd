extends HBEditorTextEdit

class_name HBEditorCodeEdit

const KEYWORDS := [
	"extends",
	"func",
	"in",
	"range",
	"var",
	"self",
	"tool",
	"signal",
	"static",
	"const",
	"enum",
	"onready",
	"export",
	"setget",
	"preload",
	"yield",
	"assert",
	"as",
	"TAU",
	"PI",
	"INF",
	"NAN",
	"and",
	"or",
	"null",
	"bool",
	"true",
	"false",
	"int",
	"float",
	"class",
]
const CONTROL_FLOW_KEYWORDS := [
	"if",
	"else",
	"elif",
	"for",
	"while",
	"break",
	"continue",
	"pass",
	"match",
	"return",
]
const BUILTIN_TYPES := [
	"AABB",
	"Array",
	"Basis",
	"Color",
	"Dictionary",
	"Nodepath",
	"Plane",
	"PoolByteArray",
	"PoolColorArray",
	"PoolIntArray",
	"PoolRealArray",
	"PoolStringArray",
	"PoolVector2Array",
	"PoolVector3Array",
	"Quad",
	"RID",
	"Rect2",
	"String",
	"Transform",
	"Transform2D",
	"Variant",
	"Vector2",
	"Vector3",
]
# These should be documented, as a user might see them in scripts
const CUSTOM_CLASSES := [
	"HBChart",
	"HBSong",
	"HBEditor",
	"HBTimingPoint",
	"HBBaseNote",
	"HBNoteData",
	"HBDoubleNote",
	"HBSustainNote",
	"HBBPMChange",
	"HBTimingChange",
	"HBIntroSkipMarker",
	"HBChartSection",
	"ScriptRunnerScript",
]

func _ready():
	for keyword in KEYWORDS:
		add_keyword_color(keyword, Color("#EE6B7E"))
	
	for keyword in CONTROL_FLOW_KEYWORDS:
		add_keyword_color(keyword, Color("#F989C9"))
	
	for _class in ClassDB.get_class_list():
		add_keyword_color(_class, Color("#7FE0C3"))
	for _class in CUSTOM_CLASSES:
		add_keyword_color(_class, Color("#7FE0C3"))
	
	# ClassDB doesnt hold itself
	add_keyword_color("ClassDB", Color("#7FE0C3"))
	
	for type in BUILTIN_TYPES:
		add_keyword_color(type, Color("41F8BD"))
	
	add_keyword_color("OK", Color("#7FE0C3"))
	
	add_color_region('"', '"', Color("#E7D795"))
	add_color_region("'", "'", Color("#E7D795"))
	add_color_region("#", "", Color("#666A74"))
