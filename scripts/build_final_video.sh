#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/build_final_video.sh [TOTAL_HOURS]
# Default: 12

TOTAL_HOURS="${1:-12}"

echo "[build_final_video] Starting build for ${TOTAL_HOURS}-hour cozy stream video..."

# Ensure scripts are executable (handy locally)
chmod +x "$(dirname "$0")"/create_base_video.sh
chmod +x "$(dirname "$0")"/loop_video.sh

# 1. Create the 1-hour base video
"./scripts/create_base_video.sh"

# 2. Loop the base video to reach TOTAL_HOURS
"./scripts/loop_video.sh" "${TOTAL_HOURS}"

FINAL_NAME="cozy_${TOTAL_HOURS}_hour_stream.mp4"
FINAL_PATH="output/${FINAL_NAME}"

echo "[build_final_video] All done. Final video: ${FINAL_PATH}"

