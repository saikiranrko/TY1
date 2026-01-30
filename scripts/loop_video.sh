#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/loop_video.sh [TOTAL_HOURS]
# Default: 0.25 hours (15 minutes)

OUTPUT_DIR="output"
BASE_VIDEO="${OUTPUT_DIR}/base_1h.mp4"

TOTAL_HOURS="${1:-0.25}" # Default to 15 minutes

# Validate TOTAL_HOURS
if ! [[ "${TOTAL_HOURS}" =~ ^[0-9.]+$ ]] || (( $(echo "${TOTAL_HOURS} <= 0" | bc -l) )); then
  echo "[loop_video] TOTAL_HOURS must be a positive number. Got: '${TOTAL_HOURS}'" >&2
  exit 1
fi

if [[ ! -f "${BASE_VIDEO}" ]]; then
  echo "[loop_video] Base video not found: ${BASE_VIDEO}"
  echo "             Run scripts/create_base_video.sh first."
  exit 1
fi

# Get the actual duration of the base video from environment or calculate if not set
BASE_VIDEO_ACTUAL_DURATION_SECONDS="${BASE_VIDEO_DURATION_SECONDS:-}"
if [[ -z "${BASE_VIDEO_ACTUAL_DURATION_SECONDS}" ]]; then
  echo "[loop_video] Warning: BASE_VIDEO_DURATION_SECONDS not set. Inferring from ffprobe."
  BASE_VIDEO_ACTUAL_DURATION_SECONDS=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${BASE_VIDEO}" | cut -d'.' -f1)
  if [[ -z "${BASE_VIDEO_ACTUAL_DURATION_SECONDS}" ]]; then
    echo "[loop_video] Error: Could not determine base video duration from '${BASE_VIDEO}'. Make sure BASE_VIDEO_DURATION_SECONDS is set." >&2
    exit 1
  fi
  echo "[loop_video] Inferred base video duration: ${BASE_VIDEO_ACTUAL_DURATION_SECONDS}s"
fi

# Calculate how many times to loop the base video
# TOTAL_HOURS is the desired final duration in hours (e.g., 0.25 for 15 mins)
# BASE_VIDEO_ACTUAL_DURATION_HOURS = BASE_VIDEO_ACTUAL_DURATION_SECONDS / 3600
# LOOPS = TOTAL_HOURS / BASE_VIDEO_ACTUAL_DURATION_HOURS
# STREAM_LOOP = LOOPS - 1 (because -stream_loop N repeats N+1 times)

# Use 'bc -l' for floating-point arithmetic
LOOPS_CALC=$(echo "scale=4; ${TOTAL_HOURS} * 3600 / ${BASE_VIDEO_ACTUAL_DURATION_SECONDS}" | bc -l)

# ffmpeg -stream_loop requires an integer. Round to nearest whole number.
STREAM_LOOP=$(printf "%.0f" "$(echo "${LOOPS_CALC} - 1" | bc -l)")

# Ensure STREAM_LOOP is not negative (e.g., if total duration is less than base video)
if (( $(echo "${STREAM_LOOP} < 0" | bc -l) )); then
  STREAM_LOOP=0
fi

OUTPUT_FILE="${OUTPUT_DIR}/cozy_${TOTAL_HOURS//./_}_hour_stream.mp4" # Replace dot for valid filename

echo "[loop_video] Creating ${TOTAL_HOURS}-hour video from base: ${BASE_VIDEO}"
echo "[loop_video] Output: ${OUTPUT_FILE}"

ffmpeg -y \
  -stream_loop "${STREAM_LOOP}" -i "${BASE_VIDEO}" \
  -c:v libx264 -preset slow -crf 20 \
  -profile:v high -level 4.1 \
  -pix_fmt yuv420p \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  -r 30 \
  "${OUTPUT_FILE}"

echo "[loop_video] Done. Final video created at: ${OUTPUT_FILE}"
