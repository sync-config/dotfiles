#!/usr/bin/env bash

require_git_repo() {
  git rev-parse --is--inside-work-tree >/dev/null 2>&1 ||
    die "current directory is not inside a Git repository"
}

get_base_branch() {
  local detected_base

  detected_base="$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|^origin/||')"

  if [[ "$detected_base" == "HEAD" ]]; then 
    detected_base=""
  fi

  echo "${FLOW_DEFAULT_BASE:-${detected_base:-dev}}"
}

has_github_workflow() {
  local workflow_dir=".github/workflows"
  [[ -d "$workflow_dir" ]] || return 1
  find "$workflow_dir" -maxdepth -1 -type f \( -name '*.yml' -o -name '*.yaml' \) | grep -q .
}
