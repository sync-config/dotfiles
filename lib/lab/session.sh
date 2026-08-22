#!/usr/bin/env bash

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
}

create_metadata() {
  cat > "${LAB_SESSION_DIR}/.lab-meta" <<EOF
LAB_REPO_ROOT=$(printf '%q' "$LAB_REPO_ROOT")
LAB_REPO_NAME=$(printf '%q' "$LAB_REPO_NAME")
LAB_TOPIC=$(printf '%q' "$LAB_TOPIC")
LAB_CREATED_AT=$(printf '%q' "$(date --iso-8601=seconds)")
LAB_BASE_COMMIT=$(printf '%q' "$LAB_BASE_COMMIT")
LAB_WORKTREE_DIR=$(printf '%q' "$LAB_WORKTREE_DIR")
EOF

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

  LAB_ACTIVE=1
  LAB_TOPIC="$LAB_TOPIC"
  LAB_ROOT="$LAB_SESSION_DIR"
  LAB_REPO="$LAB_WORKTREE_DIR"
  LAB_NOTES="$LAB_NOTES_DIR"
  LAB_LOGS="$LAB_LOGS_DIR"
  "$LAB_SHELL" -i

  unset LAB_ACTIVE LAB_TOPIC LAB_REPO LAB_NOTES LAB_LOGS
}
