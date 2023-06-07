#!/bin/bash

render_video() {
    # This function takes a directory path.
    # It then cd's into that directory and renders a video from the lyrics files.
    # If no parameter was given, it processes the current directory
    if [ -z "$1" ]; then
        echo "No parameter given, processing current directory " $(pwd)
        DIR="."
    else
        DIR="$1"
    fi

    cd "$DIR"
    # Generate an ass file from the Ultrastar Deluxe one, to use later via ffmpeg
    npx ultrastar2ass *.txt > /tmp/lyrics.ass

    MP3_FILE=$(ls *along*.mp3)
    IMAGE_FILE=$(ls *png)

    RESOLUTION="1920x1080"
    # Create a video using ffmpeg, combining the image and the mp3 file
    # and the ass file /tmp/lyrics.ass

    ffmpeg -y -loop 1 -i "$IMAGE_FILE" -i "$MP3_FILE" -vf "scale=$RESOLUTION,ass=/tmp/lyrics.ass" -shortest -c:v libx264 -tune stillimage -crf 28 -c:a aac -b:a 192k video.mp4
}

for arg in "$@"
do
    render_video "$arg"
done

# If no argument was provided, invoke it once with no arguments
if [ $# -eq 0 ]
then
    render_video
fi
