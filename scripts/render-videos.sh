#!/bin/bash

CURRENT_DIR=$PWD

render_video() {
    # This function takes a directory path.
    # It then cd's into that directory and renders a video from the lyrics files.
    # If no parameter was given, it processes the current directory
    if [ -z "$1" ]; then
        DIR="."
    else
        DIR="$1"
    fi

    RESOLUTION="1920x1080"
    cd "$DIR"
    IMAGE_FILE=$(ls *png)

    # Check preconditions:
    # * We need npx in the $PATH 
    # * We need a `notes.txt` file
    # * We need a `.flac` file
    # * We need a `.png` file that should have with and height as in $RESOLUTION
    # If any of these conditions is not met, skip return
    if ! command -v npx &> /dev/null
    then
        echo "npx could not be found"
        return
    fi
    if [ ! -f "notes.txt" ]; then
        echo "No notes.txt file found in $DIR"
        return
    fi
    if [ ! -f no_vocals.flac ]; then
        echo "No no_vocals.flac file found in $DIR"
        return
    fi
    if [ ! -f song.flac ]; then
        echo "No song.flac file found in $DIR"
        return
    fi
    if [ -z "${IMAGE_FILE}" ]; then
        echo "No .png file found in $DIR"
        return
    fi

    # Check image dimensions
    IMAGE_DIMENSIONS=$(identify -format "%wx%h" "$IMAGE_FILE")
    if [ "$IMAGE_DIMENSIONS" != "$RESOLUTION" ]; then
        echo "Image dimensions do not match $RESOLUTION"
        echo "Run this command to convert the image:"
        echo "convert \"$IMAGE_FILE\" -resize $RESOLUTION -background black -gravity center -extent $RESOLUTION $IMAGE_FILE"
        return
    fi

    # Generate a temporary file name for the lyrics file
    LYRICS_FILE=$(mktemp)

    # Generate an ass file from the Ultrastar Deluxe one, to use later via ffmpeg
    npx ultrastar2ass *.txt > ${LYRICS_FILE}
    # Replace Arial font with FantasqueSansMono
    sed -i 's/Arial/FantasqueSansMono-Bold/' $LYRICS_FILE

    if [ -f "video-karaoke.mp4" ] && [ "video-karaoke.mp4" -nt "notes.txt" ] && [ "video-karaoke.mp4" -nt "$IMAGE_FILE" ] && [ "video-karaoke.mp4" -nt "no_vocals.flac" ]; then
        echo "Skipping $DIR: video-karaoke.mp4 already exists and is up to date"
    else
        # Create a video using ffmpeg, combining the image and the flac file
        # and the ass file ${LYRICS_FILE}
        echo Building a video from no_vocals.flac and $IMAGE_FILE
        ffmpeg -y -loop 1 -i "$IMAGE_FILE" -i "no_vocals.flac" -vf "scale=$RESOLUTION,ass=${LYRICS_FILE}:fontsdir=../fonts" -shortest -c:v libx264 -tune stillimage -crf 28 -c:a aac -b:a 192k video-karaoke.mp4
    fi
    if [ -f "video.mp4" ] && [ "video.mp4" -nt "notes.txt" ] && [ "video.mp4" -nt "$IMAGE_FILE" ] && [ "video.mp4" -nt "song.flac" ]; then
        echo "Skipping $DIR: video.mp4 already exists and is up to date"
    else
        # Create a video using ffmpeg, combining the image and the flac file
        # and the ass file ${LYRICS_FILE}
        echo Building a video from song.flac and $IMAGE_FILE
        ffmpeg -y -loop 1 -i "$IMAGE_FILE" -i "song.flac" -vf "scale=$RESOLUTION,ass=${LYRICS_FILE}:fontsdir=../fonts" -shortest -c:v libx264 -tune stillimage -crf 28 -c:a aac -b:a 192k video.mp4
    fi

}

for arg in "$@"
do
    render_video "$arg"
    cd "${CURRENT_DIR}"
done

# If no argument was provided, invoke it once with no arguments
if [ $# -eq 0 ]
then
    render_video
fi
