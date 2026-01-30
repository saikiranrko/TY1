#!/usr/bin/env bash
# generate_soundscape.sh
# Improved: More distinct sounds to avoid "it sounds like rain" confusion.

set -euo pipefail

OUT_MP3="${1:-}"
THEME="${2:-}"

if [[ -z "${OUT_MP3}" ]] || [[ -z "${THEME}" ]]; then
  echo "Usage: generate_soundscape.sh <output_mp3> <THEME>" >&2
  exit 1
fi

DURATION_SECONDS="${DURATION_SECONDS:-3600}"
SR=48000

echo "[soundscape] theme=${THEME} dur=${DURATION_SECONDS}s"

case "${THEME}" in
  rain)
    # Heavy distinct droplets + Deep rolling thunder
    ffmpeg -y \
      -f lavfi -i "anoisesrc=color=white:amplitude=0.2:sample_rate=${SR}:duration=${DURATION_SECONDS}" \
      -f lavfi -i "anoisesrc=color=brown:amplitude=0.7:sample_rate=${SR}:duration=${DURATION_SECONDS}" \
      -filter_complex "\
        [0:a]highpass=f=1000,lowpass=f=3000,tremolo=f=10:d=0.8[drops]; \
        [1:a]lowpass=f=100,tremolo=f=0.1:d=1,volume=2[thunder]; \
        [drops][thunder]amix=inputs=2:weights=1 0.7:normalize=0,alimiter=limit=0.95[out]" \
      -map "[out]" -c:a libmp3lame -q:a 4 "${OUT_MP3}"
    ;;

  wind)
    # Deep howling - No white noise to avoid rain-like hiss
    ffmpeg -y \
      -f lavfi -i "anoisesrc=color=pink:amplitude=0.4:sample_rate=${SR}:duration=${DURATION_SECONDS}" \
      -filter_complex "\
        [0:a]lowpass=f=800,highpass=f=50,tremolo=f=0.15:d=0.9,aecho=0.8:0.9:200:0.5[howl]; \
        [howl]alimiter=limit=0.9[out]" \
      -map "[out]" -c:a libmp3lame -q:a 4 "${OUT_MP3}"
    ;;

  fireplace)
    # Sharp distinct crackles + very low rumble
    ffmpeg -y \
      -f lavfi -i "anoisesrc=color=white:amplitude=0.3:sample_rate=${SR}:duration=${DURATION_SECONDS}" \
      -f lavfi -i "anoisesrc=color=brown:amplitude=0.5:sample_rate=${SR}:duration=${DURATION_SECONDS}" \
      -filter_complex "\
        [0:a]highpass=f=4000,tremolo=f=15:d=1,atempo=1.2[crackle]; \
        [1:a]lowpass=f=80[embers]; \
        [crackle][embers]amix=inputs=2:weights=0.8 1.2:normalize=0,alimiter=limit=0.9[out]" \
      -map "[out]" -c:a libmp3lame -q:a 4 "${OUT_MP3}"
    ;;

  ocean)
    # Deep swoosh - very slow oscillation
    ffmpeg -y \
      -f lavfi -i "anoisesrc=color=pink:amplitude=0.5:sample_rate=${SR}:duration=${DURATION_SECONDS}" \
      -filter_complex "\
        [0:a]lowpass=f=1000,highpass=f=30,tremolo=f=0.1:d=0.95[waves]; \
        [waves]alimiter=limit=0.95[out]" \
      -map "[out]" -c:a libmp3lame -q:a 4 "${OUT_MP3}"
    ;;
    
  forest)
    # Prominent bird chirps (High pitch oscillation) + Subtle wind
    ffmpeg -y \
      -f lavfi -i "sine=f=3000:d=${DURATION_SECONDS}:s=${SR}" \
      -f lavfi -i "anoisesrc=color=pink:amplitude=0.15:sample_rate=${SR}:duration=${DURATION_SECONDS}" \
      -filter_complex "\
        [0:a]tremolo=f=8:d=1,volume=if(gt(random(0),0.98),1,0):eval=frame[birds]; \
        [1:a]lowpass=f=1500,highpass=f=300[trees]; \
        [birds][trees]amix=inputs=2:weights=1 0.4:normalize=0,alimiter=limit=0.9[out]" \
      -map "[out]" -c:a libmp3lame -q:a 4 "${OUT_MP3}"
    ;;

  *)
    ffmpeg -y -f lavfi -i "anoisesrc=color=pink:amplitude=0.2:sample_rate=${SR}:duration=${DURATION_SECONDS}" \
      -c:a libmp3lame -q:a 4 "${OUT_MP3}"
    ;;
esac
