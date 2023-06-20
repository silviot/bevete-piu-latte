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
    IMAGE_FILES=$(ls background*.png)

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
    if [ -z "${IMAGE_FILES}" ]; then
        echo "No background*.png file found in $DIR"
        return
    fi

    # Check image dimensions
    for image_file in $IMAGE_FILES; do
        echo checking $image_file;
        IMAGE_DIMENSIONS=$(identify -format "%wx%h" "$image_file")
        if [ "$IMAGE_DIMENSIONS" != "$RESOLUTION" ]; then
            echo "Image dimensions ($IMAGE_DIMENSIONS) do not match $RESOLUTION"
            echo "Converting"
            mv "$image_file" "$image_file.old"
            convert "$image_file.old" -resize $RESOLUTION -background black -gravity center -extent $RESOLUTION "$image_file"
        fi
    done
    ffmpeg_txt_file=$(generate_ffmpeg_txt)

    # Generate a temporary file name for the lyrics file
    LYRICS_FILE=$(mktemp /tmp/lyrics-XXXXXXXXX.ass)

    # Generate an ass file from the Ultrastar Deluxe one, to use later via ffmpeg
    npx ultrastar2ass *.txt > ${LYRICS_FILE}
    # Replace Arial font with FantasqueSansMono
    sed -i 's/Arial/FantasqueSansMono-Bold/' $LYRICS_FILE

    if [ -f "video-karaoke.mp4" ] && [ "video-karaoke.mp4" -nt "notes.txt" ] && [ "video-karaoke.mp4" -nt "$IMAGE_FILE" ] && [ "video-karaoke.mp4" -nt "no_vocals.flac" ]; then
        echo "Skipping $DIR: video-karaoke.mp4 already exists and is up to date"
    else
        # Create a video using ffmpeg, combining the image and the flac file
        # and the ass file ${LYRICS_FILE}
        echo Building a video from no_vocals.flac and $ffmpeg_txt_file
        ffmpeg -y -i "no_vocals.flac" -f concat -safe 0 -i "$ffmpeg_txt_file" -r 24 -vf "fps=24,subtitles=${LYRICS_FILE}:fontsdir=../fonts" -c:a aac -b:a 192k -preset ultrafast -shortest video-karaoke.mp4
    fi

    if [ -f "video.mp4" ] && [ "video.mp4" -nt "notes.txt" ] && [ "video.mp4" -nt "$IMAGE_FILE" ] && [ "video.mp4" -nt "song.flac" ]; then
        echo "Skipping $DIR: video.mp4 already exists and is up to date"
    else
        # Create a video using ffmpeg, combining the image and the flac file
        # and the ass file ${LYRICS_FILE}
        echo Building a video from song.flac and $ffmpeg_txt_file
        ffmpeg -y -i "song.flac" -f concat -safe 0 -i "$ffmpeg_txt_file" -r 24 -vf "fps=24,subtitles=${LYRICS_FILE}:fontsdir=../fonts" -c:a aac -b:a 192k -preset ultrafast -shortest video.mp4
    fi

}

generate_ffmpeg_txt() {
    # Create a temporary file to store the FFmpeg commands
    TMP_FILE=$(mktemp /tmp/ffmpeg_concat-XXXXXXXXX)

    # Loop through the image files and append FFmpeg commands to the temporary file
    while IFS= read -r -d $'\0' FILE; do
        echo "file '$FILE'" >> $TMP_FILE
        echo "duration 20" >> $TMP_FILE
    done < <(find "$PWD" -maxdepth 1 -name 'background*.png' -print0)
    # Repeat the content of the file 30 times
    for i in {1..30}; do
        cat $TMP_FILE >> $TMP_FILE.txt
    done

    # Return the path of the temporary file
    echo $TMP_FILE.txt
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
