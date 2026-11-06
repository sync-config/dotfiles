mkv2mp4burn() {
  if [[ $# -lt 1 || $# -gt 3 ]]; then
    echo "Usage:"
    echo "  mkv2mp4burn <video.mkv>"
    echo "  mkv2mp4burn <video.mkv> <subtitle.srt>"
    echo "  mkv2mp4burn <video.mkv> <subtitle.srt> <output.mp4>"
    echo "  mkv2mp4burn <video.mkv> <output.mp4>"
    return 1
  fi

  local video="$1"
  local subtitle=""
  local output=""
  local temp_sub=""

  if [[ ! -f "$video" ]]; then
    echo "Video file not found: $video"
    return 1
  fi

  if [[ $# -eq 2 ]]; then
    if [[ "$2" == *.mp4 || "$2" == *.mkv ]]; then
      output="$2"
    else
      subtitle="$2"
      output="${video%.*}.subbed.mp4"
    fi
  elif [[ $# -eq 3 ]]; then
    subtitle="$2"
    output="$3"
  else
    output="${video%.*}.subbed.mp4"
  fi

  local filter
  if [[ -n "$subtitle" ]]; then
    if [[ ! -f "$subtitle" ]]; then
      echo "Subtitle file not found: $subtitle"
      return 1
    fi

    # تشخیص انکودینگ و تبدیل خودکار CP1256 / غیر UTF-8 به UTF-8 استاندارد
    local enc
    enc=$(file -b --mime-encoding "$subtitle" 2>/dev/null || echo "unknown")
    if [[ "$enc" != "utf-8" && "$enc" != "us-ascii" ]]; then
      echo "Non-UTF-8 subtitle detected ($enc). Auto-converting to UTF-8..."
      temp_sub="$(mktemp "${TMPDIR:-/tmp}/sub_utf8_XXXXXX.srt")"
      if ! iconv -f CP1256 -t UTF-8 "$subtitle" > "$temp_sub" 2>/dev/null; then
        python3 -c "
import sys
raw = open(sys.argv[1], 'rb').read()
text = raw.decode('cp1256', errors='replace')
open(sys.argv[2], 'w', encoding='utf-8').write(text)
" "$subtitle" "$temp_sub"
      fi
      subtitle="$temp_sub"
    fi

    local clean_sub
    clean_sub=$(printf '%s' "$subtitle" | sed -e 's/\\/\\\\/g' -e "s/'/\\\\'/g" -e 's/:/\\:/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g')
    filter="subtitles='${clean_sub}':charenc=UTF-8"
    echo "Burning external subtitle: $1"
  else
    local clean_vid
    clean_vid=$(printf '%s' "$video" | sed -e 's/\\/\\\\/g' -e "s/'/\\\\'/g" -e 's/:/\\:/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g')
    filter="subtitles='${clean_vid}':si=0"
    echo "Burning first embedded subtitle from: $video"
  fi

  local duration
  duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video" 2>/dev/null)

  cleanup() {
    tput cnorm 2>/dev/null || printf "\e[?25h"
    [[ -n "$temp_sub" && -f "$temp_sub" ]] && rm -f "$temp_sub"
    [[ -n "$err_log" && -f "$err_log" ]] && rm -f "$err_log"
    trap - INT TERM EXIT
  }

  local err_log
  err_log="$(mktemp "${TMPDIR:-/tmp}/ffmpeg_err_XXXXXX.log")"

  if [[ -z "$duration" || "$duration" == "N/A" ]]; then
    trap cleanup INT TERM EXIT
    ffmpeg -y -i "$video" -map "0:v:0" -map "0:a?" -vf "$filter" -c:v libx264 -crf 18 -preset veryfast -c:a aac -b:a 192k "$output"
    cleanup
    return
  fi

  local total_sec=${duration%.*}
  [[ $total_sec -le 0 ]] && total_sec=1

  echo "Rendering to: $output"

  tput civis 2>/dev/null || printf "\e[?25l"
  trap cleanup INT TERM EXIT

  ffmpeg -nostdin -y -loglevel error -progress pipe:1 \
    -i "$video" \
    -map "0:v:0" -map "0:a?" \
    -vf "$filter" \
    -c:v libx264 -crf 18 -preset veryfast \
    -c:a aac -b:a 192k \
    "$output" 2>"$err_log" | awk -F'=' -v total="$total_sec" '
    BEGIN {
      w = 30
      printf "\r\033[K\033[1;36m[%-30s]\033[0m \033[1;32m  0%%\033[0m (00:00 / %02d:%02d)", "", int(total/60), int(total%60)
      fflush()
    }
    $1 == "out_time_us" {
      cur = int($2 / 1000000)
      pct = int((cur * 100) / total)
      if (pct > 100) pct = 100

      filled = int((pct * w) / 100)
      bar = ""
      for (i = 0; i < filled; i++) bar = bar "▓"
      for (i = filled; i < w; i++) bar = bar "░"

      printf "\r\033[K\033[1;36m[%s]\033[0m \033[1;32m%3d%%\033[0m (Time: %02d:%02d / %02d:%02d)", bar, pct, int(cur/60), int(cur%60), int(total/60), int(total%60)
      fflush()
    }
    $1 == "progress" && $2 == "end" {
      bar = ""
      for (i = 0; i < w; i++) bar = bar "▓"
      printf "\r\033[K\033[1;36m[%s]\033[0m \033[1;32m100%%\033[0m \033[1;32m✔ Done!\033[0m\n", bar
      fflush()
    }
  '

  if [[ -s "$err_log" ]]; then
    printf "\n\033[1;31m[ffmpeg error detected]:\033[0m\n"
    cat "$err_log"
  fi

  cleanup
}

alias download="cd ~/Downloads"
