extends MarginContainer

signal back

onready var rich_text_label: RichTextLabel = get_node("VBoxContainer/VBoxContainer/Panel/MarginContainer/ScrollContainer/MarginContainer/RichTextLabel")
onready var game_tab_button: HBHovereableButton = get_node("VBoxContainer/HBoxContainer/GameTab")
onready var engine_tab_button: HBHovereableButton = get_node("VBoxContainer/HBoxContainer/EngineTab")
onready var button_container: HBSimpleMenu = get_node("VBoxContainer/HBoxContainer")
onready var scroll_container: ScrollContainer = get_node("VBoxContainer/VBoxContainer/Panel/MarginContainer/ScrollContainer")

const TITLE_TEMPLATE = "[font=res://fonts/new_fonts/roboto_black_35.tres]%s[/font]\n\n"
const SCROLL_SPEED = 1500.0

const PH_AUTHORS = {
	"Patrons": preload("res://patrons.gd").PATRONS,
	"Programming": {
		"Álex Román Núñez (EIREXE)": "Lead developer, engine developer",
		"Lino Bigatti": "Volunteer developer",
	},
	"Art": {
		"Izayoi": ["Background artwork (Cloudy Sky)"],
		"Mariale": ["Background artwork (Sands of Time, Connected, Core Creation, Monochrome Stars)"],
		"Joanna Salguero (guinii)": ["Background artwork (Through the Night, ETERNAL, Love Sacrifice)"],
		"Emmilly Lima (sadnesswaifu)": ["Background artwork (Imademo, Blossoming Spell, Getaway)"],
		"Albert Navarro (Reixart)": ["Background artwork (Going my way)"],
		"Andrea Balaguer (Hikaru)": ["Background artwork (RedLine)"],
		"David Revoy": ["Used background artwork (Hyperspeed out of Control, Music Play in the Floor, Dime Linda)"],
		"Lucas Corral": ["Background artwork (Reprisal)"]
	},
	"Charting": {
		"Hunter Stevens (Yahoo)": ["Going my Way", "Through the Night", "Love Sacrifice", "Reprisal", "Confession", "Monochrome Stars"],
		"Twoncity": ["Cloudy Sky 2019", "Blossoming Spell", "Connected", "Imademo"],
		"Starbeat": ["Getaway"],
		"Blizzin": ["Sands of Time", "RedLine", "Imademo", "Core creation"],
		"Snail": ["ETERNAL"],
		"BunBun": ["Dime Linda"]
	},
	"Music": {
		"SuganoMusic": [
			"Sands of Time",
			"RedLine",
			"Imademo",
			"Cloudy Sky",
			"Getaway",
			"Music Play in the Floor",
			"Core Creation",
			"Hyperspeed out of Control",
			"Through the night"
			],
		"Galaxian Recordings": [
			"Blossoming Spell"
		],
		"Netcavy Records": [
			"Reprisal"
		],
		"Takanashi Koubou": [
			"ETERNAL",
			"Love Sacrifice",
			"Going my way",
			"Confession"
		],
		"TORAV4": [
			"Connected"
		],
		"Mixie": [
			"Dime Linda"
		]
	},
	"Charting software": {
		"PPD Editor (by KHCMaster)": [
			"Imademo 2012",
			"Sands of Time",
			"Getaway",
			"Blossoming Spell",
			"Cloudy Sky 2019",
			"Music Play in the Floor",
			"RedLine 2018",
			"Hyperspeed out of Control",
			"Connected",
		],
		"Comfy Studio (by samyuu)": [
			"Dime Linda"
		]
	},
	"Licenses" : [
		"[u]\"cover book project\"[/u] by David Revoy, licensed under Creative Commons Attribution 4.0.",
		"[u]A derivative of \"Episode 26 page 1\"[/u] by David Revoy (cropped), licensed under Creative Commons Attribution 4.0.",
		"[u]A derivative of \"Episode 33 page 2\"[/u] by David Revoy (cropped), licensed under Creative Commons Attribution 4.0.",
		"[u]\"Saffron steampunk clothes\"[/u] by David Revoy, licensed under Creative Commons Attribution 4.0.",
		"[u]Open source Nintendo Switch toolchain[/u] by devkitPro"
	],
	"Others": {
		"Gura, Gawr": "Resident mathematician",
		"Reimu Hakurei fumo": "Marketing department head",
		"Skyth & the MikuMikuLibrary contributors": "MikuMikuLibrary, used as a reference for loading MM+ content."
	}
}

const ENGINE_COPYRIGHT_INFO_ADDITIONS = [
	{
		"name": "Shinobu Engine",
		"parts": [
			{
				"copyright": ["2019-2022, Álex Román Núñez"],
				"license": "Expat"
			}
		],
	},
	{
		"name": "miniaudio",
		"parts": [
			{
				"copyright": ["2020, David Reid"],
				"license": "Public Domain (www.unlicense.org)"
			}
		],
	},
	{
		"name": "GodotSteam",
		"parts": [
			{
				"copyright": ["GP Garcia, Álex Román Núñez"],
				"license": "Expat"
			}
		]
	},
	{
		"name": "FFmpeg project",
		"parts": [
			{
				"copyright": ["FFmpeg contributors, Fabrice Bellard"],
				"license": "LGPLv2.1"
			}
		]
	}
]

func make_credits_simple(label: RichTextLabel, credits: Dictionary):
	for ind in credits:
		var oc = credits[ind]
		label.bbcode_text += "[u]%s[/u][indent]%s[/indent]\n" % [ind, oc]

func make_credits_links(label: RichTextLabel, credits: Dictionary):
	for ind in credits:
		var oc = credits[ind][0]
		label.bbcode_text += "[u]%s[/u][indent]%s[/indent]\n" % [ind, oc]

func make_credits_list(label: RichTextLabel, credits: Dictionary):
	for ind in credits:
		label.bbcode_text += "[u]%s[/u]\n" % [ind]
		for oc in credits[ind]:
			label.bbcode_text += "[indent]%s[/indent]\n" % [oc]

func make_credits_dumb(label: RichTextLabel, credits: Array):
	for credit in credits:
		label.bbcode_text += "%s\n" % [credit]

func make_title(label: RichTextLabel, title: String):
	label.bbcode_text += TITLE_TEMPLATE % title

func show_ph_credits(label: RichTextLabel):
	scroll_container.scroll_vertical = 0
	label.bbcode_text = ""
	
	label.bbcode_text += "\n"
	make_title(label, "Patrons")
	make_credits_dumb(label, PH_AUTHORS.Patrons)
	
	label.bbcode_text += "\n"
	make_title(label, "Programming")
	make_credits_simple(label, PH_AUTHORS.Programming)

	label.bbcode_text += "\n"
	make_title(label, "Art")
	make_credits_links(label, PH_AUTHORS.Art)

	label.bbcode_text += "\n"
	make_title(label, "Music")
	make_credits_list(label, PH_AUTHORS.Music)

	label.bbcode_text += "\n"
	make_title(label, "Charting")
	make_credits_list(label, PH_AUTHORS.Charting)

	label.bbcode_text += "\n"
	make_title(label, "Charting Software")
	make_credits_list(label, PH_AUTHORS["Charting software"])

	label.bbcode_text += "\n"
	make_title(label, "Licenses")
	make_credits_dumb(label, PH_AUTHORS.Licenses)

	label.bbcode_text += "\n"
	make_title(label, "Others")
	make_credits_simple(label, PH_AUTHORS.Others)
	
func show_copyright_info_engine(info: Dictionary):
	var title = info.name
	make_title(rich_text_label, title)
	for part in info.parts:
		rich_text_label.bbcode_text += "License: %s \n" % [part.license]
		for copyright in part.copyright:
			rich_text_label.bbcode_text += "[u][indent]%s[/indent][/u]\n" % [copyright]
	rich_text_label.bbcode_text += "\n"
	
func show_engine_credits(label: RichTextLabel):
	scroll_container.scroll_vertical = 0
	rich_text_label.bbcode_text = ""
	for info in ENGINE_COPYRIGHT_INFO_ADDITIONS:
		show_copyright_info_engine(info)
	for info in Engine.get_copyright_info():
		show_copyright_info_engine(info)
func _ready():
	var player_name = PlatformService.service_provider.friendly_username
	if player_name == "Player":
		player_name = "You"
	PH_AUTHORS.Others[player_name] = "Thanks to whom this game is possible"
	engine_tab_button.connect("pressed", self, "show_engine_credits", [rich_text_label])
	engine_tab_button.connect("hovered", self, "show_engine_credits", [rich_text_label])
	game_tab_button.connect("pressed", self, "show_ph_credits", [rich_text_label])
	game_tab_button.connect("hovered", self, "show_ph_credits", [rich_text_label])
	button_container.connect("focus_exited", self, "_on_focus_exited")
	show_ph_credits(rich_text_label)
	set_process(false)
	connect("focus_entered", self, "_on_focus_entered")
	
func _on_focus_entered():
	set_process(true)
	button_container.grab_focus()
	
func _on_focus_exited():
	set_process(false)
	
func _process(delta):
	if Input.is_action_pressed("gui_down"):
		scroll_container.scroll_vertical += max(SCROLL_SPEED * delta, 1)
	elif Input.is_action_pressed("gui_up"):
		scroll_container.scroll_vertical -= max(SCROLL_SPEED * delta, 1)
	if Input.is_action_just_pressed("gui_cancel"):
		HBGame.fire_and_forget_sound(HBGame.menu_back_sfx, HBGame.sfx_group)
		emit_signal("back")
		set_process(false)
