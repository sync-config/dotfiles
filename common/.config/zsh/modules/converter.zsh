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
    local clean_sub
    clean_sub=$(printf '%s' "$subtitle" | sed -e 's/\\/\\\\/g' -e "s/'/\\\\'/g" -e 's/:/\\:/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g')
    filter="subtitles='${clean_sub}':charenc=UTF-8"
    echo "Burning external subtitle: $subtitle"
  else
    local clean_vid
    clean_vid=$(printf '%s' "$video" | sed -e 's/\\/\\\\/g' -e "s/'/\\\\'/g" -e 's/:/\\:/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g')
    filter="subtitles='${clean_vid}':si=0"
    echo "Burning first embedded subtitle from: $video"
  fi

  local duration
  duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video" 2>/dev/null)

  if [[ -z "$duration" || "$duration" == "N/A" ]]; then
    ffmpeg -y -i "$video" -map "0:v:0" -map "0:a?" -vf "$filter" -c:v libx264 -crf 18 -preset veryfast -c:a aac -b:a 192k "$output"
    return
  fi

  local total_sec=${duration%.*}
  [[ $total_sec -le 0 ]] && total_sec=1

  echo "Rendering to: $output"

  tput civis 2>/dev/null || printf "\e[?25l"
  trap 'tput cnorm 2>/dev/null || printf "\e[?25h"; trap - INT TERM EXIT' INT TERM EXIT

  ffmpeg -nostdin -y -loglevel error -progress pipe:1 \
    -i "$video" \
    -map "0:v:0" -map "0:a?" \
    -vf "$filter" \
    -c:v libx264 -crf 18 -preset veryfast \
    -c:a aac -b:a 192k \
    "$output" 2>/dev/null | awk -F'=' -v total="$total_sec" '
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

  tput cnorm 2>/dev/null || printf "\e[?25h"
  trap - INT TERM EXIT
}

alias download="cd ~/Downloads"
