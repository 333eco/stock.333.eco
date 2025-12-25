#!/usr/bin/env bash

# chmod +x gif.sh
# ./gif.sh

set -euo pipefail

# Detect CPU cores
JOBS=$(sysctl -n hw.ncpu 2>/dev/null || nproc)

find . -type f -iname "*.mp4" -print0 |
xargs -0 -n 1 -P "$JOBS" bash -c '
  mp4="$1"
  dir="$(dirname "$mp4")"
  base="$(basename "$mp4" .mp4)"
  gif="$dir/$base.gif"
  palette="$dir/$base.palette.png"

  echo "🎬 Converting: $mp4 → $gif"

  ffmpeg -y -i "$mp4" \
    -vf "fps=8,scale=240:-1:flags=lanczos,palettegen" \
    "$palette"

  ffmpeg -y -i "$mp4" -i "$palette" \
    -filter_complex "fps=8,scale=240:-1:flags=lanczos[x];[x][1:v]paletteuse" \
    "$gif"

  rm -f "$palette"
' _
