#!/usr/bin/env bash
set -euo pipefail

# Generates a 1-hour ambient soundscape (rain/wind/fireplace/ocean-ish)
# purely using FFmpeg filters (no external audio files).
#
# Usage:
#   ./scripts/generate_soundscape.sh <output_mp3> [THEME]
#
# THEME: rain | wind | fireplace | ocean | random (default: random)

OUT_MP3="${1:-}"
THEME="${2:-random}"

if [[ -z "${OUT_MP3}" ]]; then
  echo "Usage: generate_soundscape.sh <output_mp3> [THEME]" >&2
  exit 1
fi

DURATION_SECONDS="${DURATION_SECONDS:-3600}"
SR="${SR:-48000}"

pick_random_theme() {
  local themes=("rain" "wind" "fireplace" "ocean")
  echo "${themes[$((RANDOM % ${#themes[@]}))]}"
}

if [[ "${THEME}" == "random" ]]; then
  THEME="$(pick_random_theme)"
fi

echo "[generate_soundscape] Theme: ${THEME}"
echo "[generate_soundscape] Duration: ${DURATION_SECONDS}s, sample_rate: ${SR}"

mkdir -p "$(dirname "${OUT_MP3}")"

# Notes:
# - We use anoisesrc as base, then filter it to resemble different ambiences.
# - We keep levels conservative to avoid clipping.
case "${THEME}" in
  rain)
    # "Rain": bright noise + some low rumble + gentle reverb-ish echo.
    ffmpeg -y -f lavfi -i "anoisesrc=color=white:amplitude=0.20:sample_rate=${SR}:duration=${DURATION_SECONDS}" \
      -filter_complex "\
        [0:a]highpass=f=500, lowpass=f=9000, acompressor=threshold=-20dB:ratio=4:attack=10:release=200 [rain]; \
        anoisesrc=color=pink:amplitude=0.08:sample_rate=${SR}:duration=${DURATION_SECONDS}, lowpass=f=250 [rumble]; \
        [rain][rumble]amix=inputs=2:normalize=0, aecho=0.6:0.7:40:0.2, alimiter=limit=0.95 [out]" \
      -map "[out]" -c:a libmp3lame -q:a 4 "${OUT_MP3}"
    ;;

  wind)
    # "Wind": low-passed pink/brown-ish noise with slow “gust” modulation.
    ffmpeg -y -f lavfi -i "anoisesrc=color=pink:amplitude=0.25:sample_rate=${SR}:duration=${DURATION_SECONDS}" \
      -filter_complex "\
        [0:a]lowpass=f=900, highpass=f=40, \
        tremolo=f=0.08:d=0.7, \
        acompressor=threshold=-22dB:ratio=3:attack=30:release=300, \
        alimiter=limit=0.95 [out]" \
      -map "[out]" -c:a libmp3lame -q:a 4 "${OUT_MP3}"
    ;;

  fireplace)
    # "Fireplace": crackle-like bandpassed noise + warm low noise bed.
    ffmpeg -y \
      -f lavfi -i "anoisesrc=color=white:amplitude=0.20:sample_rate=${SR}:duration=${DURATION_SECONDS}" \
      -f lavfi -i "anoisesrc=color=pink:amplitude=0.10:sample_rate=${SR}:duration=${DURATION_SECONDS}" \
      -filter_complex "\
        [0:a]highpass=f=2000, lowpass=f=9000, acompressor=threshold=-18dB:ratio=6:attack=5:release=80 [crackle]; \
        [1:a]lowpass=f=300, highpass=f=60, acompressor=threshold=-25dB:ratio=2.5:attack=50:release=400 [warm]; \
        [crackle][warm]amix=inputs=2:normalize=0, aecho=0.5:0.6:25:0.15, alimiter=limit=0.95 [out]" \
      -map "[out]" -c:a libmp3lame -q:a 4 "${OUT_MP3}"
    ;;

  ocean)
    # "Ocean": layered noise with slow swells; slightly brighter than wind.
    ffmpeg -y -f lavfi -i "anoisesrc=color=pink:amplitude=0.22:sample_rate=${SR}:duration=${DURATION_SECONDS}" \
      -filter_complex "\
        [0:a]lowpass=f=1800, highpass=f=40, \
        tremolo=f=0.05:d=0.8, \
        acompressor=threshold=-22dB:ratio=3:attack=40:release=350, \
        aecho=0.5:0.65:60:0.10, \
        alimiter=limit=0.95 [out]" \
      -map "[out]" -c:a libmp3lame -q:a 4 "${OUT_MP3}"
    ;;

  *)
    echo "[generate_soundscape] Unknown THEME: '${THEME}' (use rain|wind|fireplace|ocean|random)" >&2
    exit 1
    ;;
esac

echo "[generate_soundscape] Wrote: ${OUT_MP3}"

