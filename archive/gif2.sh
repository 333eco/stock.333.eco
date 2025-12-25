#!/usr/bin/env bash

# chmod +x gif.sh
# ./gif.sh

# Exit on error
set -e

# Find all mp4 files recursively
find . -type f -iname "*.mp4" | while read -r mp4; do
  dir="$(dirname "$mp4")"
  filename="$(basename "$mp4" .mp4)"
  gif="$dir/$filename.gif"

  # Skip if GIF already exists
  if [[ -f "$gif" ]]; then
    echo "Skipping (already exists): $gif"
    continue
  fi

  echo "Converting: $mp4 → $gif"

  ffmpeg -i "$mp4" -vf "fps=10,scale=320:-1" "$gif"
done
