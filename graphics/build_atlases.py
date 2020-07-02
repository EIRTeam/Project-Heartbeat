DIRECTORIES = [
	"icon_packs/playstation",
	"icon_packs/xbox",
	"fallback_icon_pack"
]

import subprocess
import os

base_cwd = os.getcwd()

for directory in DIRECTORIES:
	os.chdir(directory)
	#atlasify -o sprite.png -ast -p 2 -m 1024,1024 --extrude 1 --trim --save ./
	subprocess.call(["atlasify", "-o", "atlas.png", "-ast", "-p", "2", "--extrude", "1", "--trim", "-m", "-m 1024,1024", "--save", "./notes"])
	os.chdir(base_cwd)
