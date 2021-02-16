extends Label

signal birthday_triggered

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
	"Rolling around at the speed of tuturu", # ????
	"Shoutouts to SimpleFlips",
	"I'll never break under their madness, I'll be miles above, my head up to the sky", # Ace - I'll never break
	"Original handcrafted code!", # This code is definitely not stolen
	"The hate us because they ain't us", # The Interview reference
	"Now featuring 100% more leaderboards",
	"Project Project Disappointment", # PPD reference
	"Project Heartbeat Install from scratch tutorial", # Reference to hisokeee's video.
	"Sé que, si perdo, vosaltres també perdeu", # Reference to gohan's bird scene in Catalan,
	"T'has de enfrontar amb mi. Endevant, mira'm els ulls! No tinc cap por. Estic Segur.", # ditto
	"Shinoboooo", # Oshino Shinobu reference
	"Not portable *", # Reference to PH not being officially available on portable systems, despite there being a homebrew switch port
	":v",
	"The CEO of button mashing", # It is you
	"Bwoah", # Kimi raikkonen reference
	"Just leave me alone, I know what to do", # Ditto
	"Just being a mediocre has never been my ambition. That's not my style.", # Michael Schumacher quote
	"If God had meant for us to walk, why did he give us fingers that fit game controllers?", # Stirling Moss quote
	"Oh yeah that was easy, I can't believe it... No it wasn't", # Mika Hakkinen quote
	"MiyakiWelp MiyakiWelp",
	"In loving memory of Paçoca the rat, forever in our hearts",
	"In loving memory of Haru the cat",
	"In loving memory of Jose Luis, que la tierra te sea leve amigo",
]

const BIRTHDAYS = {
	[27, 02]: "EIREXE",
	[26, 03]: "Project Heartbeat",
	[23, 04]: "Sadnesswaifu",
	[04, 05]: "Aiko",
	[28, 08]: "Alex",
	[13, 10]: "Kami",
}

func _ready():
	text = QUOTES[randi() % QUOTES.size()]
	var date_time = OS.get_datetime()
	for birthday in BIRTHDAYS:
		if birthday[0] == date_time.day and birthday[1] == date_time.month:
			emit_signal("birthday_triggered")
			text = "Happy birthday %s!" % [BIRTHDAYS[birthday]]
	#text = QUOTES[52-6]
