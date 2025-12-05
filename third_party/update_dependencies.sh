#!/bin/sh

wget -O youtube_dl/youtube-dl "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux"
wget -O youtube_dl/youtube-dl.exe "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
wget -O ffmpeg_win_temp.zip "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-lgpl.zip"
unzip -o -j ffmpeg_win_temp.zip "ffmpeg-master-latest-win64-lgpl/bin/*" -d ffmpeg
rm ffmpeg/ffplay.exe

wget -O ffmpeg_linux_temp.tar.xz "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-lgpl.tar.xz"
tar -xvf ffmpeg_linux_temp.tar.xz --directory ffmpeg --wildcards "ffmpeg-master-latest-linux64-lgpl/bin/*" --strip-components 2
rm ffmpeg/ffplay

wget -O deno_linux_tmp.zip "https://github.com/denoland/deno/releases/download/v2.6.0/deno-x86_64-unknown-linux-gnu.zip"
unzip -o deno_linux_tmp.zip -d deno

wget -O deno_windows_tmp.zip "https://github.com/denoland/deno/releases/download/v2.6.0/deno-x86_64-pc-windows-msvc.zip"
unzip -o deno_windows_tmp.zip -d deno

rm deno_linux_tmp.zip
rm deno_windows_tmp.zip
rm ffmpeg_win_temp.zip
rm ffmpeg_linux_temp.tar.xz