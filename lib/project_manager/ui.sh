#!/usr/bin/env bash

generate_preview_cmd() {
  cat << 'EOF'
session="{}"
printf "\033[1;36mSession:\033[0m %s\n\n" "$session"

tmux display-message \
  -p \
  -t "${session}:0.0" \
  "Path: #{pane_current_path}" 2>/dev/null

printf "\n\033[1;36mWindows:\033[0m\n"
tmux list-windows \
  -t "$session" \
  -F " #{window-index}: #{window_name}" 2>/dev/null

printf "\n\033[1;36mPane output:\033[0m\n"
tmux capture-pane \
  -p \
  -e \
  -t "${session}:0.0" \
  -S -80 2>/dev/null

EOF
}

select_project_fzf() {
  local current_session="$1"
  local list_helper="$2"
  local preview_cmd
  preview_cmd="$(generate_preview_cmd)"

  "$list_helper" "$current_session" |
    fzf \
    --prompt="Project> " \
    --print-query \
    --no-multi \
    --height=100% \
    --layout=reverse \
    --border \
    --preview="$preview_cmd" \
    --preview-window='right:40%:wrap' \
    --bind="ctrl-d:execute-silent(tmux kill-session -t '{}')+reload($list_helper '$current_session')" \
    --header='CTRL-D: Delete | ENTER: Attach/Switch'
}
