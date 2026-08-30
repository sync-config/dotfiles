#!/usr/bin/env bash

ensure_session_restored() {
  if tmux list-sessions >/dev/null 2>&1; then
    return 0
  fi

  local resurrect_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
  [[ ! -d "$resurrect_dir" ]] && resurrect_dir="$HOME/.tmux/resurrect"
  local last_resurrect="$resurrect_dir/last"

  if [[ -e "$last_resurrect" || -L "$last_resurrect" ]]; then
    local restore_script="$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh"

    if [[ -f "$restore_script" ]]; then
      printf "\e[33m⚡ Restoring tmux sessions...\e[0m\r"

      tmux new-session -d -s "__resurrect_temp__" 2>/dev/null || true

      tmux run-shell "$restore_script" >/dev/null 2>&1 || true

      local count=0
      while [ $count -lt 25 ]; do
        local total_sessions
        total_sessions=$(tmux list-sessions -F '#S' 2>/dev/null | grep -v '^__resurrect_temp__$' | wc -l)
        if [ "$total_sessions" -gt 0 ]; then
          break
        fi
        sleep 0.1
        ((count++))
      done

      tmux kill-session -t "__resurrect_temp__" 2>/dev/null || true

      printf "%*s\r" 40 ""
    fi
  fi
}

