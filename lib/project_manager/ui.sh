#!/usr/bin/env bash

select_project_fzf() {
  local current_session="$1"
  local list_helper="$2"
  local preview_script="$3"

  "$list_helper" "$current_session" |
    fzf \
    --prompt="Project> " \
    --print-query \
    --no-multi \
    --height=100% \
    --layout=reverse \
    --border \
    --preview="$preview_script {}" \
    --preview-window='right:65%:wrap' \
    --bind="ctrl-d:execute-silent(tmux kill-session -t '{}')+reload($list_helper '$current_session')" \
    --header='CTRL-D: Delete | ENTER: Attach/Switch'
}
