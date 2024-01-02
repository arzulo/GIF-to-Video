# GIF-to-Video
An easy to use GIF to video converter that works on simply opening power shell shortcuts for different video conversion types. 

Two shortcuts are currently included with this repo:
1. GIF -> `.mov` container and `ProRes` codec. (supports alpha channels for video editting).
2. GIF -> `.mp4` container and `h264` codec.


Conversion setting are kept minimal and contained within the `src/` script. You will need to edit those if you are looking for alterations from my original design.

# Setup
In order for this toolset to work, an executable of `ffmpeg` will need to be provided and placed within the `src/` directory.

1. Download the latest version of `ffmpeg` from the website [here](https://www.ffmpeg.org/download.html).
    - Alternatively, get it from the github releases [here](https://github.com/BtbN/FFmpeg-Builds/releases).
2. Find the executable, usually it will be `bin/ffmpeg.exe`.
3. Assure the executable file name is `ffmpeg.exe`.
4. Place it at `src/ffmpeg.exe`.
5. Done!


# Use
Simply doube click any of the `.lnk` shortcut files found at the root of the directory. Thes will open a PowerShell window with following prompts.
