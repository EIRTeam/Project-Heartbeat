DIRECTORIES = [
	"resource_packs/fallback",
	"resource_packs/playstation",
	"resource_packs/nintendo",
	"resource_packs/xbox"
]

import subprocess
import os
import shutil
base_cwd = os.getcwd()

for directory in DIRECTORIES:
	os.chdir(directory)
	#atlasify -o sprite.png -ast -p 2 -m 1024,1024 --extrude 1 --trim --save ./

	# We will first bake the shadow for all sprites

	# magick  convert heart.png \( +clone  -background black  -shadow 80x0+8+8 \) +swap -background none -layers merge +repage  shadow_hard.png

	if not os.path.isdir("editor_resources"):
		os.mkdir("editor_resources")

	for _file in os.listdir("notes"):
		if _file.endswith(".png"):
			if not "target" in _file and not "small" in _file:
				subprocess.call(["magick", "convert", "notes/"+_file, "(", "+clone", "-background", "black", "-shadow", "80x0+6+6", ")", "+swap", "-background", "none", "-layers", "merge", "+repage", "-crop", "128x128+0+0", "editor_resources/" + _file])
			else:
				shutil.copy("notes/"+_file, "editor_resources/"+_file)
	os.chdir(base_cwd)
