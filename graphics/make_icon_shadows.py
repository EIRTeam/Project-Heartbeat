DIRECTORIES = [
	"resource_packs/fallback",
	"resource_packs/playstation",
	"resource_packs/nintendo",
	"resource_packs/xbox"
]

import subprocess
import os
import shutil
import tempfile
from pathlib import Path

base_cwd = os.getcwd()

def are_images_equal(first, second):
   if not Path(first).is_file() or not Path(second).is_file():
      return False
   compare_out = subprocess.run(["magick", "compare", "-metric", "AE", first, second, "NULL:"], encoding="utf-8", capture_output=True)
   diff = int(compare_out.stderr)
   print(diff, second)
   if diff == 0:
      return True
   return False

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
				crop_size = "128x128+0+0"
				if "_rush" in _file:
					crop_size = "256x256+0+0"
				tmp_file = tempfile.NamedTemporaryFile(suffix=".png")
				subprocess.call(["magick", "notes/"+_file, "(", "+clone", "-background", "black", "-shadow", "80x0+6+6", ")", "+swap", "-background", "none", "-layers", "merge", "+repage", "-crop", crop_size, tmp_file.name])

				out_name = "editor_resources/" + _file
				if not are_images_equal(tmp_file.name, out_name):
					shutil.copy(tmp_file.name, out_name)
				else:
					print("SKIPPING")
			else:
				shutil.copy("notes/"+_file, "editor_resources/"+_file)
	os.chdir(base_cwd)
