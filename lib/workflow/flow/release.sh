#!/usr/bin/env bash

cmd_release() {
  local version="${1:-}"
  local develop_branch="dev"
  local main_branch="main"

  if [[ -z "$version" ]]; then
    die "Usage: flow release <version_number> (e.g., flow release 1.0.0)"
  fi

  require_git_repo

  if [[ -n "$(git status --porcelain)" ]]; then
    git status --short
    die "You have uncommitted changes; commit or stash them before releasing."
  fi

  info "Starting release process for version v$version..."

  git checkout "$develop_branch" || die "Could not switch to $develop_branch"
  git pull origin "$develop_branch" --ff-only

  git checkout "$main_branch" || die "Could not switch to $main_branch"
  git pull origin "$main_branch" --ff-only

  local release_branch="release/v$version"
  git checkout -b "$release_branch" "$develop_branch"

  git checkout "$main_branch"
  git merge --no-ff "$release_branch" -m "Merge branch '$release_branch' into $main_branch" || die "Merge conflict on $main_branch"
  
  info "Tagging release v$version..."
  git tag -a "v$version" -m "Release version v$version"

  git checkout "$develop_branch"
  git merge --no-ff "$release_branch" -m "Merge branch '$release_branch' into $develop_branch" || die "Merge conflict on $develop_branch"

  info "Pushing branches and tags to origin..."
  git push origin "$main_branch" "$develop_branch" --tags

  git branch -d "$release_branch"

  info "Release v$version completed successfully! Back on '$develop_branch'."
}
