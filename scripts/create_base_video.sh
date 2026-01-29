#!/usr/bin/env bash
set -euo pipefail

# Configuration
AUDIO_DIR="audio"
VIDEO_DIR="video"
OUTPUT_DIR="output"

AUDIO_FILE="${AUDIO_DIR}/cozy_music.mp3"
BACKGROUND_IMAGE="${VIDEO_DIR}/background.png"
BASE_VIDEO="${OUTPUT_DIR}/base_1h.mp4"
GENERATED_AUDIO="${OUTPUT_DIR}/generated_soundscape.mp3"

# Base duration: 1 hour in seconds
BASE_DURATION_SECONDS=3600

mkdir -p "${AUDIO_DIR}" "${VIDEO_DIR}" "${OUTPUT_DIR}"

echo "[create_base_video] Using FFmpeg version:"
ffmpeg -version | head -n 1 || true

# Simple randomness so each run looks/sounds a bit different.
RANDOM_SEED=${RANDOM}
echo "[create_base_video] Random seed: ${RANDOM_SEED}"

########################################
# 1. Create fresh audio every run (soundscape)
########################################
THEME="${THEME:-random}"  # rain|wind|fireplace|ocean|random
export DURATION_SECONDS="${BASE_DURATION_SECONDS}"
echo "[create_base_video] Generating new audio soundscape (THEME=${THEME})..."
chmod +x "./scripts/generate_soundscape.sh"
./scripts/generate_soundscape.sh "${GENERATED_AUDIO}" "${THEME}"

########################################
# 2. Ensure background image exists
########################################
if [[ ! -f "${BACKGROUND_IMAGE}" ]]; then
  echo "[create_base_video] '${BACKGROUND_IMAGE}' not found. Generating cozy background image..."

  # Choose a random cozy color from a small palette.
  COZY_COLORS=( "#2b1b3f" "#3b2349" "#1e2a3a" "#2f3b52" "#3b2c35" )
  COLOR_INDEX=$((RANDOM % ${#COZY_COLORS[@]}))
  SELECTED_COLOR="${COZY_COLORS[$COLOR_INDEX]}"
  echo "[create_base_video] Using random cozy color: ${SELECTED_COLOR}"

  ffmpeg -y -f lavfi -i "color=c=${SELECTED_COLOR}:size=1920x1080:duration=1" \
    -frames:v 1 "${BACKGROUND_IMAGE}"
else
  echo "[create_base_video] Found existing background image: ${BACKGROUND_IMAGE}"
fi

########################################
# 3. Create 1-hour base video
########################################
echo "[create_base_video] Creating 1-hour base video at 1920x1080 @ 30fps..."

ffmpeg -y \
  -loop 1 -framerate 30 -i "${BACKGROUND_IMAGE}" \
  -i "${GENERATED_AUDIO}" \
  -c:v libx264 -preset veryslow -tune stillimage -crf 18 \
  -c:a aac -b:a 128k \
  -pix_fmt yuv420p \
  -shortest \
  -t ${BASE_DURATION_SECONDS} \
  "${BASE_VIDEO}"

echo "[create_base_video] Done. Base video created at: ${BASE_VIDEO}"

