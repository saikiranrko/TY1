#!/bin/bash
# make_seamless_loop.sh
# Uses the "Ping-Pong" method (Forward + Reverse).
# This is 100% seamless visually.

set -e

INPUT=$1
OUTPUT=$2
TARGET_DURATION=${3:-30}

if [ -z "$INPUT" ] || [ -z "$OUTPUT" ]; then
    echo "Usage: ./scripts/make_seamless_loop.sh <input> <output> <duration>"
    exit 1
fi

DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT")

echo "[loop] Source: ${DUR}s, Target: ${TARGET_DURATION}s (Ping-Pong)"

# Create Forward + Reverse concat
ffmpeg -y -i "$INPUT" -filter_complex \
    "[0:v]reverse[rev]; [0:v][rev]concat=n=2:v=1:a=0[v_pingpong]" \
    -map "[v_pingpong]" -c:v libx264 -preset superfast -pix_fmt yuv420p "output/temp_pingpong.mp4"

# Loop IT
ffmpeg -y -stream_loop -1 -i "output/temp_pingpong.mp4" -t "${TARGET_DURATION}" -c:v libx264 -preset superfast -pix_fmt yuv420p "$OUTPUT"
rm output/temp_pingpong.mp4
echo "[loop] Done: $OUTPUT"
