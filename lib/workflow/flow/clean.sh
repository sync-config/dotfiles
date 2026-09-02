#!/usr/bin/env bash

cmd_clean() {
  local root=""
  local branch=""
  local base=""
  local detected_base


  require_git_repo

  root="$(git rev-parse --show-toplevel)"
  cd "$root"

  branch="$(git branch --show-current)"
  base="$(get_base_branch)"

  if [[ "$branch" == "$base" ]]; then
    die "You are already on the base branch '$base'. Run this command from the feature branch you want to clean."
  fi

  info "Preparing to clean branch '$branch'..."

  info "Switching to base branch '$base'..."
  git switch "$base"

  info "Updating '$base' from remote..."
  git pull origin "$base" --ff-only || warning "Could not fast-forward '$base' from remote. Pls check manually."

  git remote prune origin >/dev/null 2>&1 || true

  info "Deleting local branch '$branch'..."
  if git branch -d "$branch" >/dev/null 2>&1; then
    info "Successfully deleted branch '$branch'."
  else
    printf "⚠️ Branch '%s' is not fully merged into '%s'. Force delete? [y/N]: " "$branch" "$base"
    local response=""
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      git branch -D "$branch"
      info "Force deleted branch '$branch'."
    else
      info "Clean cancelled. Branch '$branch' was kept."
      git switch "$branch"
      return
    fi
  fi
}
