extends Label

const QUOTES = [
	"On the wings of a dream",
	"Dangerous choking hazard!",
	"No plastic instruments required!",
	"Voca- what?",
	"Ahh, this stuff is really fresh",
	"Cha-cha now y'all",
	"Imagine the nerves",
	"Machinations A",
	"NO SHE DID NOT CREATE MINECRAFT YOU MANIAC",
	"Many hentai games led to this"
]

func _ready():
	text = QUOTES[randi() % QUOTES.size()]
