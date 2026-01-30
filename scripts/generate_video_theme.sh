#!/usr/bin/env bash
# generate_video_theme.sh
# Final High-Sensation Version: Visuals match Audio for all themes.

set -euo pipefail

OUT_MP4="${1:-}"
THEME="${2:-}"
BG_PATH="${3:-}"

# Dynamic parameters
RAIN_INTENSITY="${RAIN_INTENSITY:-0.2}"
COLOR_SHIFT="${COLOR_SHIFT:-#1a2a3a}"
DURATION_SECONDS="${DURATION_SECONDS:-3600}"
WIDTH=1920
HEIGHT=1080

echo "[generate_video_theme] theme=${THEME} bg=$(basename "${BG_PATH}") dur=${DURATION_SECONDS}"

IS_VIDEO=false
if [[ "${BG_PATH}" == *.mp4 ]] || [[ "${BG_PATH}" == *.mkv ]]; then
    IS_VIDEO=true
fi

INPUT_ARGS=()
if [[ -n "${BG_PATH}" && -f "${BG_PATH}" ]]; then
    if [ "$IS_VIDEO" = true ]; then
        INPUT_ARGS+=("-stream_loop" "-1" "-i" "${BG_PATH}")
    else
        INPUT_ARGS+=("-loop" "1" "-i" "${BG_PATH}")
    fi
else
    INPUT_ARGS+=("-f" "lavfi" "-i" "color=c=${COLOR_SHIFT}:s=${WIDTH}x${HEIGHT}:d=${DURATION_SECONDS}")
fi

# Camera movement
CAMERA_FX="scale=2112:1188,crop=1920:1080:96+40*sin(t/15):54+30*cos(t/22)"

case "${THEME}" in
  rain)
    # Visual: Sparse Rain + Lightning
    LIGHTNING="eq=brightness='if(gt(random(0),0.999),0.2,0)'"
    ffmpeg -y "${INPUT_ARGS[@]}" \
      -filter_complex "\
        [0:v]${CAMERA_FX},format=yuv420p,${LIGHTNING}[base]; \
        color=c=white:s=${WIDTH}x${HEIGHT}:d=${DURATION_SECONDS},format=rgba[white]; \
        [white]noise=alls=100:allf=t,format=rgba,geq=a='gt(p(X,Y),254)*150',scroll=v=0.4[rain]; \
        [base][rain]overlay=format=auto[video]" \
      -map "[video]" -c:v libx264 -preset ultrafast -crf 23 -t "${DURATION_SECONDS}" "${OUT_MP4}"
    ;;

  wind)
    # Visual: Dust Particles + Slight Shake
    SHAKE="crop=1920:1080:96+40*sin(t/15)+2*sin(t*10):54+30*cos(t/22)+2*cos(t*12)"
    ffmpeg -y "${INPUT_ARGS[@]}" \
      -filter_complex "\
        [0:v]scale=2112:1188,${SHAKE},format=yuv420p[base]; \
        color=c=gray:s=${WIDTH}x${HEIGHT}:d=${DURATION_SECONDS},format=rgba[gray]; \
        [gray]noise=alls=100:allf=t,format=rgba,geq=a='gt(p(X,Y),254)*80',scroll=h=0.5[dust]; \
        [base][dust]overlay=format=auto[video]" \
      -map "[video]" -c:v libx264 -preset ultrafast -crf 23 -t "${DURATION_SECONDS}" "${OUT_MP4}"
    ;;

  fireplace)
    # Visual: Warm Tint + Rising Embers
    WARMTH="colorlevels=rim=0.1:gim=0.0:bim=-0.1"
    ffmpeg -y "${INPUT_ARGS[@]}" \
      -filter_complex "\
        [0:v]${CAMERA_FX},${WARMTH},format=yuv420p[base]; \
        color=c=orange:s=${WIDTH}x${HEIGHT}:d=${DURATION_SECONDS},format=rgba[orange]; \
        [orange]noise=alls=100:allf=t,format=rgba,geq=a='gt(p(X,Y),254)*200',scroll=v=-0.2[embers]; \
        [base][embers]overlay=format=auto[video]" \
      -map "[video]" -c:v libx264 -preset ultrafast -crf 23 -t "${DURATION_SECONDS}" "${OUT_MP4}"
    ;;

  *)
    # Default: Smooth Camera Movement
    ffmpeg -y "${INPUT_ARGS[@]}" \
      -filter_complex "[0:v]${CAMERA_FX},format=yuv420p[v]" \
      -map "[v]" -c:v libx264 -preset ultrafast -crf 23 -t "${DURATION_SECONDS}" "${OUT_MP4}"
    ;;
esac

echo "[generate_video_theme] Success: ${OUT_MP4}"
