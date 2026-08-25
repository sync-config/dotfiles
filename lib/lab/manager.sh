#!/usr/bin/env bash

lab_list() {
  local session_dir meta_file
  local repo_name topic created_at dirty_marker

  shopt -s nullglob

  for session_dir in "$LAB_BASE_DIR"/*/;do
    meta_file="${session_dir}.lab-meta"

    [[ -f "$meta_file" ]] || continue

    source "$meta_file"

    repo_name="${LAB_REPO_NAME:-unknown}"
    topic="${LAB_TOPIC:-unknown}"
    created_at="${LAB_CREATED_AT:-unknown}"
    dirty_marker=""

    if [[ -d "${LAB_WORKTREE_DIR:-}" ]]; then
      if [[ -n "$(git -C "$LAB_WORKTREE_DIR" status --porcelain 2>/dev/null)" ]]; then
        dirty_marker="●"
      fi
    else
      dirty_marker="!"
    fi

    printf '%s\t%s\t%s\t%s\t%s\n' \
      "${session_dir%/}" \
      "$dirty_marker" \
      "$repo_name" \
      "$topic" \
      "$created_at"
  done
}

lab_create_from_current_repo() {
  local topic="$1"

  [[ -n "$topic" ]] || {
    lab_warn "Lab name is empty."
    return 1
  }

  if [[ "${LAB_ACTIVE:-}" == "1" ]]; then
    lab_warn "Leave the current Lab first; nested Labs are disabled."
    return 1
  fi

  LAB_REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" \
    || {
      lab_warn "To create a Lab, run 'lab' from inside a Git repository."
      return 1
    }

  parse_args "$topic"

  require_git_repository
  create_session

  if ! create_worktree; then
    lab_warn "Worktree creation failed. Removing incomplete Lab."
    rm -rf -- "$LAB_SESSION_DIR"
    return 1
  fi

  create_metadata
  entry_lab_shell
}

lab_open_session() {
  local session_dir="$1"
  local meta_file="${session_dir}/.lab-meta"

  [[ -d "$session_dir" ]] || {
    lab_warn "Lab directory does not exist."
    return 1
  }

  [[ -f "$meta_file" ]] || {
    lab_warn "Invalid Lab: metadata file is missing."
    return 1
  }

  # shellcheck disable=SC1090
  source "$meta_file"

  LAB_SESSION_DIR="$session_dir"
  LAB_NOTES_DIR="${session_dir}/notes"
  LAB_LOGS_DIR="${session_dir}/logs"

  entry_lab_shell
}

lab_delete_session() {
  local session_dir="$1"
  local meta_file="${session_dir}/.lab-meta"
  local answer

  [[ -f "$meta_file" ]] || {
    lab_warn "Invalid Lab metadata."
    return 1
  }

  # shellcheck disable=SC1090
  source "$meta_file"

  if [[ -d "${LAB_REPO_ROOT:-}" && -d "${LAB_WORKTREE_DIR:-}" ]]; then
    git -C "$LAB_REPO_ROOT" worktree remove --force "$LAB_WORKTREE_DIR" \
      || lab_warn "Git could not cleanly remove the worktree."
  fi

  rm -rf -- "$session_dir"

  lab_info "Lab deleted."
}

lab_preview() {
  local session_dir="$1"
  local meta_file="${session_dir}/.lab-meta"

  [[ -f "$meta_file" ]] || exit 0

  # shellcheck disable=SC1090
  source "$meta_file"

  printf 'Repository: %s\n' "${LAB_REPO_NAME:-unknown}"
  printf 'Topic:      %s\n' "${LAB_TOPIC:-unknown}"
  printf 'Created:    %s\n' "${LAB_CREATED_AT:-unknown}"
  printf 'Commit:     %s\n' "${LAB_BASE_COMMIT:-unknown}"
  printf 'Path:       %s\n' "$session_dir"

  printf '\n--- Git status ---\n'

  if [[ -d "${LAB_WORKTREE_DIR:-}" ]]; then
    git -C "$LAB_WORKTREE_DIR" status --short 2>/dev/null || true

    printf '\n--- Last commits ---\n'
    git -C "$LAB_WORKTREE_DIR" log --oneline -5 2>/dev/null || true
  else
    printf 'Worktree is missing.\n'
  fi

  printf '\n--- Notes ---\n'
  find "${session_dir}/notes" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null || true
}

lab_dashboard_notice() {
  local message="${1:-}"

  message="${message//$'\n'/ }"
  message="$(printf '%s' "$message" | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"

  printf '%s' "$message"
}

lab_dashboard() {
  command -v fzf >/dev/null 2>&1 \
    || lab_die "fzf is required. Install it first."

  local result
  local query
  local action
  local selected
  local session_dir
  local deleted_topic
  local opened_topic
  local delete_output
  local fzf_status

  local dashboard_dir="$PWD"
  local dashboard_message="Type a name and press Enter to create a new Lab."

  while true; do
    set +e

    result="$(
      lab_list | fzf \
        --ansi \
        --delimiter=$'\t' \
        --with-nth=2,3,4,5 \
        --prompt='Labs > ' \
        --height='75%' \
        --layout=reverse \
        --border \
        --print-query \
        --expect='enter,ctrl-d' \
        --header="$dashboard_message" \
        --header-first \
        --preview="$HOME/.dotfiles/scripts/lab-preview {1}" \
        --preview-window='right:40%:wrap'
    )"

    fzf_status=$?

    set -e

    if [[ "$fzf_status" -eq 130 ]]; then
      break
    fi

    if [[ "$fzf_status" -ne 0 && -z "$result" ]]; then
      continue
    fi

    query="$(printf '%s\n' "$result" | sed -n '1p')"
    action="$(printf '%s\n' "$result" | sed -n '2p')"
    selected="$(printf '%s\n' "$result" | sed -n '3p')"

    if [[ "${LAB_DEBUG:-0}" == "1" ]]; then
      {
        printf '\n========== FZF DEBUG ==========\n'
        printf 'fzf_status: %s\n' "$fzf_status"
        printf 'query:      %q\n' "$query"
        printf 'action:     %q\n' "$action"
        printf 'selected:   %q\n' "$selected"
        printf '================================\n'
      } >&9
    fi

    case "$action" in
      ctrl-d)
        if [[ -z "$selected" ]]; then
          dashboard_message="⚠ Select a Lab first."
          continue
        fi

        session_dir="$(printf '%s' "$selected" | cut -f1)"
        deleted_topic="$(printf '%s' "$selected" | awk -F $'\t' '{print $4}')"

        cd "$dashboard_dir" || {
          dashboard_message="✗ Could not return to dashboard directory."
          continue
        }

        if delete_output="$(lab_delete_session "$session_dir" 2>&1)"; then
          dashboard_message="✓ Lab deleted: ${deleted_topic:-unknown}"
        else
          dashboard_message="$(
            lab_dashboard_notice "✗ Delete failed: $delete_output"
          )"
        fi

        continue
        ;;

      enter|"")
        if [[ -n "$selected" ]]; then
          session_dir="$(printf '%s' "$selected" | cut -f1)"
          opened_topic="$(printf '%s' "$selected" | awk -F $'\t' '{print $4}')"

          cd "$dashboard_dir" || {
            dashboard_message="✗ Could not return to dashboard directory."
            continue
          }

          if lab_open_session "$session_dir"; then
            dashboard_message="← Returned from Lab: ${opened_topic:-unknown}"
          else
            dashboard_message="✗ Could not open Lab: ${opened_topic:-unknown}"
          fi

        elif [[ -n "$query" ]]; then
          cd "$dashboard_dir" || {
            dashboard_message="✗ Could not return to dashboard directory."
            continue
          }

          if lab_create_from_current_repo "$query"; then
            dashboard_message="✓ Created and returned from Lab: $query"
          else
            dashboard_message="✗ Could not create Lab: $query"
          fi

        else
          dashboard_message="⚠ Type a Lab name or select an existing Lab."
        fi
        ;;
    esac
  done
}
