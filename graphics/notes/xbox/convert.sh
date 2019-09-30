#!/bin/sh

for file in *.svg
do
     /usr/bin/inkscape -z -f "${file}" -w 128 --export-area-page -e "${file%.svg}.png"
     /usr/bin/inkscape -z -f "${file}" -w 64 --export-area-page -e "${file%.svg}_small.png"
done

