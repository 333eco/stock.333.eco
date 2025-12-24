#!/usr/bin/env sh

# chmod +x watermark.sh
# ./watermark.sh

set -eu

WATERMARK="hb.png"

# Detect CPU cores (POSIX-safe)
PARALLEL_JOBS="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

process_file() {
  input="$1"

  ext="${input##*.}"
  ext="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"
  tmp="${input%.*}.tmp.$ext"

  case "$ext" in
    mp4)
      WM_SIZE=50
      ffmpeg -y -loglevel error \
        -i "$input" -i "$WATERMARK" \
        -filter_complex \
        "[1]scale=${WM_SIZE}:-1,format=rgba,colorchannelmixer=aa=0.9[wm];\
         [0][wm]overlay=W-w-10:H-h-10" \
        -c:v h264_videotoolbox \
        -pix_fmt yuv420p \
        -c:a copy \
        "$tmp"
      ;;
    jpg|jpeg)
      WM_SIZE=80
      ffmpeg -y -loglevel error \
        -i "$input" -i "$WATERMARK" \
        -filter_complex \
        "[1]scale=${WM_SIZE}:-1,format=rgba,colorchannelmixer=aa=0.9[wm];\
         [0][wm]overlay=W-w-15:H-h-15" \
        "$tmp"
      ;;
    gif)
      WM_SIZE=25
      ffmpeg -y -loglevel error \
        -i "$input" -i "$WATERMARK" \
        -filter_complex \
        "[1]scale=${WM_SIZE}:-1,format=rgba,colorchannelmixer=aa=0.9[wm];\
         [0][wm]overlay=W-w-5:H-h-5" \
        -gifflags -transdiff \
        "$tmp"
      ;;
    *)
      echo "Skipping unsupported file: $input"
      return 0
      ;;
  esac

  if [ $? -eq 0 ]; then
    mv "$tmp" "$input"
    echo "✔ Watermarked: $input"
  else
    rm -f "$tmp"
    echo "✖ Failed: $input"
  fi
}

export WATERMARK
export -f process_file 2>/dev/null || true

find . -type f \( \
    -iname "*.mp4" -o \
    -iname "*.jpg" -o \
    -iname "*.jpeg" -o \
    -iname "*.gif" \
  \) -print0 |
  xargs -0 -n 1 -P "$PARALLEL_JOBS" sh -c '
    process_file "$1"
  ' _ 
