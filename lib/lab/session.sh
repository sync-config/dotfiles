#!/usr/bin/env bash

LAB_CLEANED_UP=0

create_session() {
  LAB_SESSION_DIR="$(
    mktemp -d -p "$LAB_BASE_DIR" \
      "${LAB_PREFIX}-${LAB_REPO_NAME}-${LAB_SAFE_TOPIC}-XXXXXX"
    )"

    LAB_WORKTREE_DIR="${LAB_SESSION_DIR}/repo"
    LAB_NOTES_DIR="${LAB_SESSION_DIR}/notes"
    LAB_LOGS_DIR="${LAB_SESSION_DIR}/logs"

    mkdir -p "$LAB_NOTES_DIR" "$LAB_LOGS_DIR"

    lab_info "Repository: $LAB_REPO_ROOT"
    lab_info "Topic: $LAB_TOPIC"
    lab_info "Session: $LAB_SESSION_DIR"

    trap cleanup_lab EXIT INT TERM
}

create_metadata() {
  cat > "${LAB_SESSION_DIR}/README.md" <<EOF
# Lab session

- **Repository:** \`${LAB_REPO_ROOT}\`
- **Topic:** \`${LAB_TOPIC}\`
- **Created:** \`$(date --iso-8601=seconds)\`
- **Base commit:** \`${LAB_BASE_COMMIT}\`

## Directories

- \`repo/\` — Disposable Git worktree
- \`notes/\` — Temporary notes
- \`logs/\` — Command output or experiment logs

> This directory is disposable.
> Exit the lab shell to remove it.
EOF
}

cleanup_lab() {
  local exit_code=$?

  # Prevent multiple invocations caused by EXIT + INT/TERM.
  if [[ "$LAB_CLEANED_UP" -eq 1 ]]; then
    return
  fi

  LAB_CLEANED_UP=1

  printf "\n"
  lab_info "Cleaning up..."

  # Remove the Git worktree registration first.
  remove_worktree

  # Then remove notes/logs/metadata and any remaining files.
  if [[ -n "${LAB_SESSION_DIR:-}" && -d "${LAB_SESSION_DIR:-}" ]]; then
    rm -rf -- "$LAB_SESSION_DIR"
    lab_info "Remove: $LAB_SESSION_DIR"
  fi

  # Avoid triggering the EXIT trap again.
  trap - EXIT INT TERM
  exit "$exit_code"
}

entry_lab_shell() {
  lab_info "Sandbox is ready"
  lab_info "Exit the shell to delete this session."
  printf "\n"

  cd "$LAB_WORKTREE_DIR"

  export LAB_ACTIVE=1
  export LAB_TOPIC
  export LAB_ROOT="$LAB_SESSION_DIR"
  export LAB_REPO="$LAB_WORKTREE_DIR"
  export LAB_NOTES="$LAB_NOTES_DIR"
  export LAB_LOGS="$LAB_LOGS_DIR"

  "$LAB_SHELL" -i
}
