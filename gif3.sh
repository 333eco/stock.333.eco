#!/usr/bin/env sh

# chmod +x gif2.sh
# ./gif2.sh

set -eu

CPU_CORES="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
JOBS=$((CPU_CORES / 2))
[ "$JOBS" -lt 1 ] && JOBS=1

counter="$(mktemp)"
lockdir="$(mktemp -d)"
echo 0 > "$counter"

cleanup() {
  rm -f "$counter"
  rmdir "$lockdir" 2>/dev/null || true
}
trap cleanup EXIT

# Count files first
TOTAL="$(find . -type f -iname "*.mp4" | wc -l | tr -d ' ')"

if [ "$TOTAL" -eq 0 ]; then
  echo "No MP4 files found."
  exit 0
fi

echo "🎞️  Found $TOTAL MP4 files"
echo "⚙️  Using $JOBS parallel jobs"
echo

process_mp4() {
  mp4="$1"
  dir="$(dirname "$mp4")"
  base="$(basename "$mp4" .mp4)"
  gif="$dir/$base.gif"
  palette="$dir/$base.palette.png"

  # POSIX mutex using mkdir
  while ! mkdir "$lockdir/lock" 2>/dev/null; do
    sleep 0.05
  done

  count="$(cat "$counter")"
  count=$((count + 1))
  echo "$count" > "$counter"
  rmdir "$lockdir/lock"

  echo "[$count/$TOTAL] 🎬 Converting: $mp4 → $gif"

  ffmpeg -y -loglevel error -stats \
    -i "$mp4" \
    -vf "fps=8,scale=240:-1:flags=lanczos,palettegen" \
    "$palette"

  ffmpeg -y -loglevel error -stats \
    -i "$mp4" -i "$palette" \
    -filter_complex \
    "fps=8,scale=240:-1:flags=lanczos[x];[x][1:v]paletteuse" \
    "$gif"

  rm -f "$palette"

  echo "✔ Done: $gif"
  echo
}

export -f process_mp4 2>/dev/null || true

find . -type f -iname "*.mp4" -print0 |
xargs -0 -n 1 -P "$JOBS" sh -c '
  process_mp4 "$1"
' _
