extends Label

const QUOTES = [
	"On the wings of a dream", # TTFAF reference
	"Dangerous choking hazard!", # Reference to plastic instruments
	"No plastic instruments required!",
	"Voca- what?", # Vocaloid reference
	"Ahh, this stuff is really fresh", # Famous sample
	"Cha-cha now y'all",
	"Imagine the nerves", # Clone hero Soulless 4 meme
	"Machinations A", # Soulless 4 meme
	"NO SHE DID NOT CREATE MINECRAFT YOU MANIAC", # Miku meme
	"Many hentai games led to this", # Most of EIREXE's previous serious projects were adult games
	"Mental rhythm therapy", # EIREXE reference
	"Allô, oui c'est Twingo", # Reference to the legendary Renault Twingo
	"He will attack if you go out through this door", # Twingo meme
	"Alex's singing passion", # Reference to miku's singing passion (a hard song)
	"Excellent-o" # Reference to miku's pronounciation of excellent in PD games
]

func _ready():
	text = QUOTES[randi() % QUOTES.size()]
