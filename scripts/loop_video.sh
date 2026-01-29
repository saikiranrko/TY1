#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/loop_video.sh [TOTAL_HOURS]
# Default: 12 hours

OUTPUT_DIR="output"
BASE_VIDEO="${OUTPUT_DIR}/base_1h.mp4"

TOTAL_HOURS="${1:-12}"

if ! [[ "${TOTAL_HOURS}" =~ ^[0-9]+$ ]] || [[ "${TOTAL_HOURS}" -lt 1 ]]; then
  echo "[loop_video] TOTAL_HOURS must be a positive integer. Got: '${TOTAL_HOURS}'"
  exit 1
fi

if [[ ! -f "${BASE_VIDEO}" ]]; then
  echo "[loop_video] Base video not found: ${BASE_VIDEO}"
  echo "             Run scripts/create_base_video.sh first."
  exit 1
fi

LOOPS="${TOTAL_HOURS}"          # 1-hour base, so hours == number of loops
STREAM_LOOP=$((LOOPS - 1))      # -stream_loop N repeats N+1 times

OUTPUT_FILE="${OUTPUT_DIR}/cozy_${TOTAL_HOURS}_hour_stream.mp4"

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

