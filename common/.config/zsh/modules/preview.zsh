preview() {
  local input="${1:-}"
  local name="${2:-}"
  local start="${3:-00:00:00}"

  local gif_limit=$((500 * 1024))
  local gif_output mp4_output tmp_gif
  local height fps size
  local gif_done=0

  if [[ -z "$input" ]]; then
    echo "Usage: preview input.mkv [output-name] [start-time]"
    echo "Example: preview video.mkv"
    echo "Example: preview video.mkv demo 00:01:20"
    return 1
  fi

  if [[ ! -f "$input" ]]; then
    echo "❌ File not found: $input"
    return 1
  fi

  if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "❌ ffmpeg is not installed."
    return 1
  fi

  if [[ -z "$name" ]]; then
    name="${input:t:r}"
  fi

  gif_output="${name}-preview.gif"
  mp4_output="${name}-instagram.mp4"
  tmp_gif="${name}-preview.tmp.gif"

  echo "🎬 Input: $input"
  echo "⏱️  Start: $start"
  echo "⌛ Duration: کل ویدئو"
  echo ""

  echo "📱 Creating Instagram MP4..."

  if ! ffmpeg -hide_banner -y \
    -ss "$start" \
    -i "$input" \
    -map 0:v:0 \
    -map '0:a?' \
    -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1" \
    -c:v libx264 \
    -preset medium \
    -crf 20 \
    -pix_fmt yuv420p \
    -movflags +faststart \
    -c:a aac \
    -b:a 128k \
    "$mp4_output"
  then
    echo "❌ MP4 creation failed."
    return 1
  fi

  echo "✅ MP4: $mp4_output"
  echo ""

  echo "🖼️  Creating GIF below 500KB..."
  echo "⚠️  GIF کل ویدئو ممکن است برای رسیدن به 500KB کیفیت بسیار پایینی بگیرد."

  for height in 360 300 240 200 160 140 120 100 80; do
    for fps in 10 8 6 5 4 3 2 1; do
      echo "   Trying ${height}px / ${fps}fps..."

      rm -f -- "$tmp_gif"

      if ! ffmpeg -hide_banner -loglevel error -y \
        -ss "$start" \
        -i "$input" \
        -filter_complex "[0:v]fps=${fps},scale=-2:${height}:flags=lanczos,split[a][b];[a]palettegen=max_colors=64:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=3" \
        -loop 0 \
        "$tmp_gif"
      then
        echo "   ⚠️  Failed."
        continue
      fi

      [[ -f "$tmp_gif" ]] || continue

      size=$(stat -c%s "$tmp_gif" 2>/dev/null)

      if [[ -n "$size" ]] && (( size <= gif_limit )); then
        mv -- "$tmp_gif" "$gif_output"
        gif_done=1
        echo "✅ GIF: $gif_output ($(( size / 1024 )) KB)"
        break 2
      fi
    done
  done

  rm -f -- "$tmp_gif"

  if (( gif_done == 0 )); then
    echo ""
    echo "⚠️  GIF زیر 500KB ساخته نشد."
    echo "MP4 با موفقیت ساخته شد:"
    echo "   $mp4_output"
    return 2
  fi

  echo ""
  echo "🎉 Done:"
  echo "   MP4 → $mp4_output"
  echo "   GIF → $gif_output"
}
