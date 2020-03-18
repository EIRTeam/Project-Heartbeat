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
	"Excellent-o", # Reference to miku's pronounciation of excellent in PD games
	"STOP BEING THEM", # Reference to daniel ricciardo
	"You can be my new best friend", # Reference
	"International Turururru Association", # ???
	"Into the Heartbeat", # WOWOWOWOO YOU BETTER TAKE YOUR CHANCES RIGHT NOW
	"Stop being them", # Daniel Ricciardo reference
	"One more time to escape from all this madness", # My spirit will go on by DF
	"When in doubt, blame blizzin", # Blizzin's math is weird
	"Your beauty cures all the anxieties in my heart", # Let's see if you can guess who said this
	"Project Heartbeat V-Spec Nur", # Nissan Skyline R34 reference
	"The heart is a lie, she plans to burn you", # Portalish reference (also hi xna)
	"If she saves you, it's likely her name starts with an E", # Sadnesswaifu yosi yosi
	"Smooooooooth operatooooooor", # Reference to Carlos Sainz Junior
	"Rolling around at the speed of tuturu" # ????
]

func _ready():
	text = QUOTES[randi() % QUOTES.size()]
