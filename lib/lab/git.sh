#!/usr/bin/env bash

require_git_repository() {
  LAB_REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" \
    || lab_die "run 'lab' from inside a Git repository"

  LAB_REPO_NAME=$(basename "$LAB_REPO_ROOT")
  LAB_BASE_COMMIT=$(git -C "$LAB_REPO_ROOT" rev-parse --short HEAD)
}

create_worktree() {
  lab_info "Creating detached Git worktree..."

  git -C "$LAB_REPO_ROOT" worktree add --detach "$LAB_WORKTREE_DIR" HEAD
}

remove_worktree() {
  [[ -n "${LAB_WORKTREE_DIR:-}" ]] || return 0
  [[ -d "$LAB_WORKTREE_DIR" ]] || return 0

  git -C "$LAB_REPO_ROOT" worktree remove --force "$LAB_WORKTREE_DIR" \
    || lab_warn "could not remove worktree cleanly"
}
