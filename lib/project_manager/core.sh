#!/usr/bin/env bash

get_current_session() {
  if [ -n "${TMUX:-}" ]; then
    tmux display-message -p "#S" 2>/dev/null || true
  fi
}

validate_session_name() {
  local name="$1"
  if [[ -z "$name" || "$name" == */* || "$name" == .* ]]; then
    printf 'Invalid session name: %s\n' "$name" >&2
    return 1
  fi
  return 0
}

session_exists() {
  local session="$1"
  tmux has-session -t "$session" 2>/dev/null
}

connect_session() {
  local session="$1"
  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$session"
  else
    tmux attach-session -t "$session"
  fi
}

create_session() {
  local session="$1"
  local dir="$2"

  mkdir -p "$dir" || return 1

  if [ -n "${TMUX:-}" ]; then
    tmux new-session -d -s "$session" -c "$dir" || return 1
    tmux switch-client -t "$session"
  else
    tmux new-session -s "$session" -c "$dir"
  fi
}
