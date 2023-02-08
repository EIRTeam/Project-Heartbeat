extends HBEditorTextEdit

class_name HBEditorCodeEdit

const KEYWORDS := [
	"extends",
	"func",
	"in",
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
	"as",
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

# Built from the docs using a regex :pokeslow:
const GDSCRIPT_BUILTINS = [
	"Color8",
	"ColorN",
	"abs",
	"acos",
	"asin",
	"assert",
	"atan",
	"atan2",
	"bytes2var",
	"cartesian2polar",
	"ceil",
	"char",
	"clamp",
	"convert",
	"cos",
	"cosh",
	"db2linear",
	"decimals",
	"dectime",
	"deep_equal",
	"deg2rad",
	"dict2inst",
	"ease",
	"exp",
	"floor",
	"fmod",
	"fposmod",
	"funcref",
	"get_stack",
	"hash",
	"inst2dict",
	"instance_from_id",
	"inverse_lerp",
	"is_equal_approx",
	"is_inf",
	"is_instance_valid",
	"is_nan",
	"is_zero_approx",
	"len",
	"lerp",
	"lerp_angle",
	"linear2db",
	"load",
	"log",
	"max",
	"min",
	"move_toward",
	"nearest_po2",
	"ord",
	"parse_json",
	"polar2cartesian",
	"posmod",
	"pow",
	"preload",
	"print",
	"print_debug",
	"print_stack",
	"printerr",
	"printraw",
	"prints",
	"printt",
	"push_error",
	"push_warning",
	"rad2deg",
	"rand_range",
	"rand_seed",
	"randf",
	"randi",
	"randomize",
	"range",
	"range_lerp",
	"round",
	"seed",
	"sign",
	"sin",
	"sinh",
	"smoothstep",
	"sqrt",
	"step_decimals",
	"stepify",
	"str",
	"str2var",
	"tan",
	"tanh",
	"to_json",
	"type_exists",
	"typeof",
	"validate_json",
	"var2bytes",
	"var2str",
	"weakref",
	"wrapf",
	"wrapi",
	"yield",
	"PI",
	"TAU",
	"INF",
	"NAN",
]
const GLOBALSCOPE_ENUM_ITEMS = [
	"MARGIN_LEFT",
	"MARGIN_TOP",
	"MARGIN_RIGHT",
	"MARGIN_BOTTOM",
	"CORNER_TOP_LEFT",
	"CORNER_TOP_RIGHT",
	"CORNER_BOTTOM_RIGHT",
	"CORNER_BOTTOM_LEFT",
	"VERTICAL",
	"HORIZONTAL",
	"HALIGN_LEFT",
	"HALIGN_CENTER",
	"HALIGN_RIGHT",
	"VALIGN_TOP",
	"VALIGN_CENTER",
	"VALIGN_BOTTOM",
	"SPKEY",
	"KEY_ESCAPE",
	"KEY_TAB",
	"KEY_BACKTAB",
	"KEY_BACKSPACE",
	"KEY_ENTER",
	"KEY_KP_ENTER",
	"KEY_INSERT",
	"KEY_DELETE",
	"KEY_PAUSE",
	"KEY_PRINT",
	"KEY_SYSREQ",
	"KEY_CLEAR",
	"KEY_HOME",
	"KEY_END",
	"KEY_LEFT",
	"KEY_UP",
	"KEY_RIGHT",
	"KEY_DOWN",
	"KEY_PAGEUP",
	"KEY_PAGEDOWN",
	"KEY_SHIFT",
	"KEY_CONTROL",
	"KEY_META",
	"KEY_ALT",
	"KEY_CAPSLOCK",
	"KEY_NUMLOCK",
	"KEY_SCROLLLOCK",
	"KEY_F1",
	"KEY_F2",
	"KEY_F3",
	"KEY_F4",
	"KEY_F5",
	"KEY_F6",
	"KEY_F7",
	"KEY_F8",
	"KEY_F9",
	"KEY_F10",
	"KEY_F11",
	"KEY_F12",
	"KEY_F13",
	"KEY_F14",
	"KEY_F15",
	"KEY_F16",
	"KEY_KP_MULTIPLY",
	"KEY_KP_DIVIDE",
	"KEY_KP_SUBTRACT",
	"KEY_KP_PERIOD",
	"KEY_KP_ADD",
	"KEY_KP_0",
	"KEY_KP_1",
	"KEY_KP_2",
	"KEY_KP_3",
	"KEY_KP_4",
	"KEY_KP_5",
	"KEY_KP_6",
	"KEY_KP_7",
	"KEY_KP_8",
	"KEY_KP_9",
	"KEY_SUPER_L",
	"KEY_SUPER_R",
	"KEY_MENU",
	"KEY_HYPER_L",
	"KEY_HYPER_R",
	"KEY_HELP",
	"KEY_DIRECTION_L",
	"KEY_DIRECTION_R",
	"KEY_BACK",
	"KEY_FORWARD",
	"KEY_STOP",
	"KEY_REFRESH",
	"KEY_VOLUMEDOWN",
	"KEY_VOLUMEMUTE",
	"KEY_VOLUMEUP",
	"KEY_BASSBOOST",
	"KEY_BASSUP",
	"KEY_BASSDOWN",
	"KEY_TREBLEUP",
	"KEY_TREBLEDOWN",
	"KEY_MEDIAPLAY",
	"KEY_MEDIASTOP",
	"KEY_MEDIAPREVIOUS",
	"KEY_MEDIANEXT",
	"KEY_MEDIARECORD",
	"KEY_HOMEPAGE",
	"KEY_FAVORITES",
	"KEY_SEARCH",
	"KEY_STANDBY",
	"KEY_OPENURL",
	"KEY_LAUNCHMAIL",
	"KEY_LAUNCHMEDIA",
	"KEY_LAUNCH0",
	"KEY_LAUNCH1",
	"KEY_LAUNCH2",
	"KEY_LAUNCH3",
	"KEY_LAUNCH4",
	"KEY_LAUNCH5",
	"KEY_LAUNCH6",
	"KEY_LAUNCH7",
	"KEY_LAUNCH8",
	"KEY_LAUNCH9",
	"KEY_LAUNCHA",
	"KEY_LAUNCHB",
	"KEY_LAUNCHC",
	"KEY_LAUNCHD",
	"KEY_LAUNCHE",
	"KEY_LAUNCHF",
	"KEY_UNKNOWN",
	"KEY_SPACE",
	"KEY_EXCLAM",
	"KEY_QUOTEDBL",
	"KEY_NUMBERSIGN",
	"KEY_DOLLAR",
	"KEY_PERCENT",
	"KEY_AMPERSAND",
	"KEY_APOSTROPHE",
	"KEY_PARENLEFT",
	"KEY_PARENRIGHT",
	"KEY_ASTERISK",
	"KEY_PLUS",
	"KEY_COMMA",
	"KEY_MINUS",
	"KEY_PERIOD",
	"KEY_SLASH",
	"KEY_0",
	"KEY_1",
	"KEY_2",
	"KEY_3",
	"KEY_4",
	"KEY_5",
	"KEY_6",
	"KEY_7",
	"KEY_8",
	"KEY_9",
	"KEY_COLON",
	"KEY_SEMICOLON",
	"KEY_LESS",
	"KEY_EQUAL",
	"KEY_GREATER",
	"KEY_QUESTION",
	"KEY_AT",
	"KEY_A",
	"KEY_B",
	"KEY_C",
	"KEY_D",
	"KEY_E",
	"KEY_F",
	"KEY_G",
	"KEY_H",
	"KEY_I",
	"KEY_J",
	"KEY_K",
	"KEY_L",
	"KEY_M",
	"KEY_N",
	"KEY_O",
	"KEY_P",
	"KEY_Q",
	"KEY_R",
	"KEY_S",
	"KEY_T",
	"KEY_U",
	"KEY_V",
	"KEY_W",
	"KEY_X",
	"KEY_Y",
	"KEY_Z",
	"KEY_BRACKETLEFT",
	"KEY_BACKSLASH",
	"KEY_BRACKETRIGHT",
	"KEY_ASCIICIRCUM",
	"KEY_UNDERSCORE",
	"KEY_QUOTELEFT",
	"KEY_BRACELEFT",
	"KEY_BAR",
	"KEY_BRACERIGHT",
	"KEY_ASCIITILDE",
	"KEY_NOBREAKSPACE",
	"KEY_EXCLAMDOWN",
	"KEY_CENT",
	"KEY_STERLING",
	"KEY_CURRENCY",
	"KEY_YEN",
	"KEY_BROKENBAR",
	"KEY_SECTION",
	"KEY_DIAERESIS",
	"KEY_COPYRIGHT",
	"KEY_ORDFEMININE",
	"KEY_GUILLEMOTLEFT",
	"KEY_NOTSIGN",
	"KEY_HYPHEN",
	"KEY_REGISTERED",
	"KEY_MACRON",
	"KEY_DEGREE",
	"KEY_PLUSMINUS",
	"KEY_TWOSUPERIOR",
	"KEY_THREESUPERIOR",
	"KEY_ACUTE",
	"KEY_MU",
	"KEY_PARAGRAPH",
	"KEY_PERIODCENTERED",
	"KEY_CEDILLA",
	"KEY_ONESUPERIOR",
	"KEY_MASCULINE",
	"KEY_GUILLEMOTRIGHT",
	"KEY_ONEQUARTER",
	"KEY_ONEHALF",
	"KEY_THREEQUARTERS",
	"KEY_QUESTIONDOWN",
	"KEY_AGRAVE",
	"KEY_AACUTE",
	"KEY_ACIRCUMFLEX",
	"KEY_ATILDE",
	"KEY_ADIAERESIS",
	"KEY_ARING",
	"KEY_AE",
	"KEY_CCEDILLA",
	"KEY_EGRAVE",
	"KEY_EACUTE",
	"KEY_ECIRCUMFLEX",
	"KEY_EDIAERESIS",
	"KEY_IGRAVE",
	"KEY_IACUTE",
	"KEY_ICIRCUMFLEX",
	"KEY_IDIAERESIS",
	"KEY_ETH",
	"KEY_NTILDE",
	"KEY_OGRAVE",
	"KEY_OACUTE",
	"KEY_OCIRCUMFLEX",
	"KEY_OTILDE",
	"KEY_ODIAERESIS",
	"KEY_MULTIPLY",
	"KEY_OOBLIQUE",
	"KEY_UGRAVE",
	"KEY_UACUTE",
	"KEY_UCIRCUMFLEX",
	"KEY_UDIAERESIS",
	"KEY_YACUTE",
	"KEY_THORN",
	"KEY_SSHARP",
	"KEY_DIVISION",
	"KEY_YDIAERESIS",
	"KEY_CODE_MASK",
	"KEY_MODIFIER_MASK",
	"KEY_MASK_SHIFT",
	"KEY_MASK_ALT",
	"KEY_MASK_META",
	"KEY_MASK_CTRL",
	"KEY_MASK_CMD",
	"KEY_MASK_KPAD",
	"KEY_MASK_GROUP_SWITCH",
	"BUTTON_LEFT",
	"BUTTON_RIGHT",
	"BUTTON_MIDDLE",
	"BUTTON_XBUTTON1",
	"BUTTON_XBUTTON2",
	"BUTTON_WHEEL_UP",
	"BUTTON_WHEEL_DOWN",
	"BUTTON_WHEEL_LEFT",
	"BUTTON_WHEEL_RIGHT",
	"BUTTON_MASK_LEFT",
	"BUTTON_MASK_RIGHT",
	"BUTTON_MASK_MIDDLE",
	"BUTTON_MASK_XBUTTON1",
	"BUTTON_MASK_XBUTTON2",
	"JOY_INVALID_OPTION",
	"JOY_BUTTON_0",
	"JOY_BUTTON_1",
	"JOY_BUTTON_2",
	"JOY_BUTTON_3",
	"JOY_BUTTON_4",
	"JOY_BUTTON_5",
	"JOY_BUTTON_6",
	"JOY_BUTTON_7",
	"JOY_BUTTON_8",
	"JOY_BUTTON_9",
	"JOY_BUTTON_10",
	"JOY_BUTTON_11",
	"JOY_BUTTON_12",
	"JOY_BUTTON_13",
	"JOY_BUTTON_14",
	"JOY_BUTTON_15",
	"JOY_BUTTON_16",
	"JOY_BUTTON_17",
	"JOY_BUTTON_18",
	"JOY_BUTTON_19",
	"JOY_BUTTON_20",
	"JOY_BUTTON_21",
	"JOY_BUTTON_22",
	"JOY_BUTTON_MAX",
	"JOY_SONY_CIRCLE",
	"JOY_SONY_X",
	"JOY_SONY_SQUARE",
	"JOY_SONY_TRIANGLE",
	"JOY_XBOX_B",
	"JOY_XBOX_A",
	"JOY_XBOX_X",
	"JOY_XBOX_Y",
	"JOY_DS_A",
	"JOY_DS_B",
	"JOY_DS_X",
	"JOY_DS_Y",
	"JOY_VR_GRIP",
	"JOY_VR_PAD",
	"JOY_VR_TRIGGER",
	"JOY_OCULUS_AX",
	"JOY_OCULUS_BY",
	"JOY_OCULUS_MENU",
	"JOY_OPENVR_MENU",
	"JOY_SELECT",
	"JOY_START",
	"JOY_DPAD_UP",
	"JOY_DPAD_DOWN",
	"JOY_DPAD_LEFT",
	"JOY_DPAD_RIGHT",
	"JOY_GUIDE",
	"JOY_MISC1",
	"JOY_PADDLE1",
	"JOY_PADDLE2",
	"JOY_PADDLE3",
	"JOY_PADDLE4",
	"JOY_TOUCHPAD",
	"JOY_L",
	"JOY_L2",
	"JOY_L3",
	"JOY_R",
	"JOY_R2",
	"JOY_R3",
	"JOY_AXIS_0",
	"JOY_AXIS_1",
	"JOY_AXIS_2",
	"JOY_AXIS_3",
	"JOY_AXIS_4",
	"JOY_AXIS_5",
	"JOY_AXIS_6",
	"JOY_AXIS_7",
	"JOY_AXIS_8",
	"JOY_AXIS_9",
	"JOY_AXIS_MAX",
	"JOY_ANALOG_LX",
	"JOY_ANALOG_LY",
	"JOY_ANALOG_RX",
	"JOY_ANALOG_RY",
	"JOY_ANALOG_L2",
	"JOY_ANALOG_R2",
	"JOY_VR_ANALOG_TRIGGER",
	"JOY_VR_ANALOG_GRIP",
	"JOY_OPENVR_TOUCHPADX",
	"JOY_OPENVR_TOUCHPADY",
	"MIDI_MESSAGE_NOTE_OFF",
	"MIDI_MESSAGE_NOTE_ON",
	"MIDI_MESSAGE_AFTERTOUCH",
	"MIDI_MESSAGE_CONTROL_CHANGE",
	"MIDI_MESSAGE_PROGRAM_CHANGE",
	"MIDI_MESSAGE_CHANNEL_PRESSURE",
	"MIDI_MESSAGE_PITCH_BEND",
	"MIDI_MESSAGE_SYSTEM_EXCLUSIVE",
	"MIDI_MESSAGE_QUARTER_FRAME",
	"MIDI_MESSAGE_SONG_POSITION_POINTER",
	"MIDI_MESSAGE_SONG_SELECT",
	"MIDI_MESSAGE_TUNE_REQUEST",
	"MIDI_MESSAGE_TIMING_CLOCK",
	"MIDI_MESSAGE_START",
	"MIDI_MESSAGE_CONTINUE",
	"MIDI_MESSAGE_STOP",
	"MIDI_MESSAGE_ACTIVE_SENSING",
	"MIDI_MESSAGE_SYSTEM_RESET",
	"OK",
	"FAILED",
	"ERR_UNAVAILABLE",
	"ERR_UNCONFIGURED",
	"ERR_UNAUTHORIZED",
	"ERR_PARAMETER_RANGE_ERROR",
	"ERR_OUT_OF_MEMORY",
	"ERR_FILE_NOT_FOUND",
	"ERR_FILE_BAD_DRIVE",
	"ERR_FILE_BAD_PATH",
	"ERR_FILE_NO_PERMISSION",
	"ERR_FILE_ALREADY_IN_USE",
	"ERR_FILE_CANT_OPEN",
	"ERR_FILE_CANT_WRITE",
	"ERR_FILE_CANT_READ",
	"ERR_FILE_UNRECOGNIZED",
	"ERR_FILE_CORRUPT",
	"ERR_FILE_MISSING_DEPENDENCIES",
	"ERR_FILE_EOF",
	"ERR_CANT_OPEN",
	"ERR_CANT_CREATE",
	"ERR_QUERY_FAILED",
	"ERR_ALREADY_IN_USE",
	"ERR_LOCKED",
	"ERR_TIMEOUT",
	"ERR_CANT_CONNECT",
	"ERR_CANT_RESOLVE",
	"ERR_CONNECTION_ERROR",
	"ERR_CANT_ACQUIRE_RESOURCE",
	"ERR_CANT_FORK",
	"ERR_INVALID_DATA",
	"ERR_INVALID_PARAMETER",
	"ERR_ALREADY_EXISTS",
	"ERR_DOES_NOT_EXIST",
	"ERR_DATABASE_CANT_READ",
	"ERR_DATABASE_CANT_WRITE",
	"ERR_COMPILATION_FAILED",
	"ERR_METHOD_NOT_FOUND",
	"ERR_LINK_FAILED",
	"ERR_SCRIPT_FAILED",
	"ERR_CYCLIC_LINK",
	"ERR_INVALID_DECLARATION",
	"ERR_DUPLICATE_SYMBOL",
	"ERR_PARSE_ERROR",
	"ERR_BUSY",
	"ERR_SKIP",
	"ERR_HELP",
	"ERR_BUG",
	"ERR_PRINTER_ON_FIRE",
	"PROPERTY_HINT_NONE",
	"PROPERTY_HINT_RANGE",
	"PROPERTY_HINT_EXP_RANGE",
	"PROPERTY_HINT_ENUM",
	"PROPERTY_HINT_ENUM_SUGGESTION",
	"PROPERTY_HINT_EXP_EASING",
	"PROPERTY_HINT_LENGTH",
	"PROPERTY_HINT_KEY_ACCEL",
	"PROPERTY_HINT_FLAGS",
	"PROPERTY_HINT_LAYERS_2D_RENDER",
	"PROPERTY_HINT_LAYERS_2D_PHYSICS",
	"PROPERTY_HINT_LAYERS_2D_NAVIGATION",
	"PROPERTY_HINT_LAYERS_3D_RENDER",
	"PROPERTY_HINT_LAYERS_3D_PHYSICS",
	"PROPERTY_HINT_LAYERS_3D_NAVIGATION",
	"PROPERTY_HINT_FILE",
	"PROPERTY_HINT_DIR",
	"PROPERTY_HINT_GLOBAL_FILE",
	"PROPERTY_HINT_GLOBAL_DIR",
	"PROPERTY_HINT_RESOURCE_TYPE",
	"PROPERTY_HINT_MULTILINE_TEXT",
	"PROPERTY_HINT_PLACEHOLDER_TEXT",
	"PROPERTY_HINT_COLOR_NO_ALPHA",
	"PROPERTY_HINT_IMAGE_COMPRESS_LOSSY",
	"PROPERTY_HINT_IMAGE_COMPRESS_LOSSLESS",
	"PROPERTY_HINT_LOCALE_ID",
	"PROPERTY_USAGE_STORAGE",
	"PROPERTY_USAGE_EDITOR",
	"PROPERTY_USAGE_NETWORK",
	"PROPERTY_USAGE_EDITOR_HELPER",
	"PROPERTY_USAGE_CHECKABLE",
	"PROPERTY_USAGE_CHECKED",
	"PROPERTY_USAGE_INTERNATIONALIZED",
	"PROPERTY_USAGE_GROUP",
	"PROPERTY_USAGE_CATEGORY",
	"PROPERTY_USAGE_NO_INSTANCE_STATE",
	"PROPERTY_USAGE_RESTART_IF_CHANGED",
	"PROPERTY_USAGE_SCRIPT_VARIABLE",
	"PROPERTY_USAGE_DEFAULT",
	"PROPERTY_USAGE_DEFAULT_INTL",
	"PROPERTY_USAGE_NOEDITOR",
	"METHOD_FLAG_NORMAL",
	"METHOD_FLAG_EDITOR",
	"METHOD_FLAG_NOSCRIPT",
	"METHOD_FLAG_CONST",
	"METHOD_FLAG_REVERSE",
	"METHOD_FLAG_VIRTUAL",
	"METHOD_FLAG_FROM_SCRIPT",
	"METHOD_FLAG_VARARG",
	"METHOD_FLAGS_DEFAULT",
	"TYPE_NIL",
	"TYPE_BOOL",
	"TYPE_INT",
	"TYPE_REAL",
	"TYPE_STRING",
	"TYPE_VECTOR2",
	"TYPE_RECT2",
	"TYPE_VECTOR3",
	"TYPE_TRANSFORM2D",
	"TYPE_PLANE",
	"TYPE_QUAT",
	"TYPE_AABB",
	"TYPE_BASIS",
	"TYPE_TRANSFORM",
	"TYPE_COLOR",
	"TYPE_NODE_PATH",
	"TYPE_RID",
	"TYPE_OBJECT",
	"TYPE_DICTIONARY",
	"TYPE_ARRAY",
	"TYPE_RAW_ARRAY",
	"TYPE_INT_ARRAY",
	"TYPE_REAL_ARRAY",
	"TYPE_STRING_ARRAY",
	"TYPE_VECTOR2_ARRAY",
	"TYPE_VECTOR3_ARRAY",
	"TYPE_COLOR_ARRAY",
	"TYPE_MAX",
	"OP_EQUAL",
	"OP_NOT_EQUAL",
	"OP_LESS",
	"OP_LESS_EQUAL",
	"OP_GREATER",
	"OP_GREATER_EQUAL",
	"OP_ADD",
	"OP_SUBTRACT",
	"OP_MULTIPLY",
	"OP_DIVIDE",
	"OP_NEGATE",
	"OP_POSITIVE",
	"OP_MODULE",
	"OP_STRING_CONCAT",
	"OP_SHIFT_LEFT",
	"OP_SHIFT_RIGHT",
	"OP_BIT_AND",
	"OP_BIT_OR",
	"OP_BIT_XOR",
	"OP_BIT_NEGATE",
	"OP_AND",
	"OP_OR",
	"OP_XOR",
	"OP_NOT",
	"OP_IN",
	"OP_MAX",
]

const KEYWORD_COLOR := Color("#EE6B7E")
const CONTROL_FLOW_COLOR := Color("#F989C9")
const CLASS_COLOR := Color("#7FE0C3")
const TYPE_COLOR := Color("#41F8BD")
const ENUM_COLOR := Color("#F88868")
const STRING_COLOR := Color("#E7D795")
const COMMENT_COLOR := Color("#666A74")

const FONT_LICENSE := """
This software contains a copy of the Ubunto Mono font. The license for this font is given below:

-------------------------------
UBUNTU FONT LICENCE Version 1.0
-------------------------------

PREAMBLE
This licence allows the licensed fonts to be used, studied, modified and
redistributed freely. The fonts, including any derivative works, can be
bundled, embedded, and redistributed provided the terms of this licence
are met. The fonts and derivatives, however, cannot be released under
any other licence. The requirement for fonts to remain under this
licence does not require any document created using the fonts or their
derivatives to be published under this licence, as long as the primary
purpose of the document is not to be a vehicle for the distribution of
the fonts.

DEFINITIONS
"Font Software" refers to the set of files released by the Copyright
Holder(s) under this licence and clearly marked as such. This may
include source files, build scripts and documentation.

"Original Version" refers to the collection of Font Software components
as received under this licence.

"Modified Version" refers to any derivative made by adding to, deleting,
or substituting -- in part or in whole -- any of the components of the
Original Version, by changing formats or by porting the Font Software to
a new environment.

"Copyright Holder(s)" refers to all individuals and companies who have a
copyright ownership of the Font Software.

"Substantially Changed" refers to Modified Versions which can be easily
identified as dissimilar to the Font Software by users of the Font
Software comparing the Original Version with the Modified Version.

To "Propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy. Propagation includes copying,
distribution (with or without modification and with or without charging
a redistribution fee), making available to the public, and in some
countries other activities as well.

PERMISSION & CONDITIONS
This licence does not grant any rights under trademark law and all such
rights are reserved.

Permission is hereby granted, free of charge, to any person obtaining a
copy of the Font Software, to propagate the Font Software, subject to
the below conditions:

1) Each copy of the Font Software must contain the above copyright
notice and this licence. These can be included either as stand-alone
text files, human-readable headers or in the appropriate machine-
readable metadata fields within text or binary files as long as those
fields can be easily viewed by the user.

2) The font name complies with the following:
(a) The Original Version must retain its name, unmodified.
(b) Modified Versions which are Substantially Changed must be renamed to
avoid use of the name of the Original Version or similar names entirely.
(c) Modified Versions which are not Substantially Changed must be
renamed to both (i) retain the name of the Original Version and (ii) add
additional naming elements to distinguish the Modified Version from the
Original Version. The name of such Modified Versions must be the name of
the Original Version, with "derivative X" where X represents the name of
the new work, appended to that name.

3) The name(s) of the Copyright Holder(s) and any contributor to the
Font Software shall not be used to promote, endorse or advertise any
Modified Version, except (i) as required by this licence, (ii) to
acknowledge the contribution(s) of the Copyright Holder(s) or (iii) with
their explicit written permission.

4) The Font Software, modified or unmodified, in part or in whole, must
be distributed entirely under this licence, and must not be distributed
under any other licence. The requirement for fonts to remain under this
licence does not affect any document created using the Font Software,
except any version of the Font Software extracted from a document
created using the Font Software may only be distributed under this
licence.

TERMINATION
This licence becomes null and void if any of the above conditions are
not met.

DISCLAIMER
THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF
COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM OTHER
DEALINGS IN THE FONT SOFTWARE.
"""

func _init():
	var font_license_path := "user://font_license.txt"
	
	var file = File.new()
	if not file.file_exists(font_license_path):
		file.open(font_license_path, File.WRITE)
		
		file.store_string(FONT_LICENSE)

func _ready():
	for keyword in KEYWORDS:
		add_keyword_color(keyword, KEYWORD_COLOR)
	
	for fn in GDSCRIPT_BUILTINS:
		add_keyword_color(fn, KEYWORD_COLOR)
	
	for keyword in CONTROL_FLOW_KEYWORDS:
		add_keyword_color(keyword, CONTROL_FLOW_COLOR)
	
	for _class in ClassDB.get_class_list():
		add_keyword_color(_class, CLASS_COLOR)
	for _class in CUSTOM_CLASSES:
		add_keyword_color(_class, CLASS_COLOR)
	
	# ClassDB doesnt hold itself
	add_keyword_color("ClassDB", CLASS_COLOR)
	
	for type in BUILTIN_TYPES:
		add_keyword_color(type, TYPE_COLOR)
	
	for item in GLOBALSCOPE_ENUM_ITEMS:
		add_keyword_color(item, ENUM_COLOR)
	
	add_color_region('"', '"', STRING_COLOR)
	add_color_region("'", "'", STRING_COLOR)
	add_color_region("#", "", COMMENT_COLOR)
	
	update_font_size()

func _gui_input(event):
	if event is InputEventKey and visible and get_focus_owner() == self:
		if event.is_action_pressed("editor_scale_up", false, true):
			UserSettings.user_settings.editor_code_font_size += 1
			UserSettings.save_user_settings()
			update_font_size()
		
		if event.is_action_pressed("editor_scale_down", false, true):
			UserSettings.user_settings.editor_code_font_size -= 1
			UserSettings.save_user_settings()
			update_font_size()

func update_font_size():
	get_font("font").set_size(UserSettings.user_settings.editor_code_font_size)
