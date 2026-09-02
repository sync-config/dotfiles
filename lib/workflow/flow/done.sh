#!/usr/bin/env bash

cmd_done() {
  local root=""
  local branch=""
  local base=""
  local pr_url=""
  local pr_title="${1:-}"
  local pr_body="${2:-}"

  require_git_repo
  require_command gh
  require_command act

  root="$(git rev-parse --show-toplevel)"
  cd "$root"

  branch="$(git branch --show-current)"
  base="$(get_base_branch)"

  [[ -n "$branch" ]] || die "deteched HEAD; switch to a branch first"

  if [[ "$branch" == "$base" ]]; then
    die "cannot run 'flow done on the base branch '$base'"
  fi

  if ! git show-ref --verify --quiet "refs/heads/$base" &&
    ! git show-ref --verify --quiet "refs/remotes/origin/$base"; then
  die "base branch '$base' does not exist; set FLOW_DEFAULT_BASE correctly"
  fi

  if [[ -n "$(git status --porcelain)" ]]; then
    git status --short
    die "you have uncommitted changes; commit or stach them before 'flow done'"
  fi

  if [[ "$(git rev-list --count "$base..$branch")" -eq 0 ]]; then
    die "branch '$branch' has no commits ahead of '$base'"
  fi

  info "pushing branch '$branch' to origin"

  if git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' >/dev/null 2>&1; then
    git push
  else
    git push --set-upstream origin "$branch"
  fi

  info "checking Pull Request status"

  if pr_url="$(gh pr view '$branch' --json url --jg '.url' 2>/dev/null)"; then
    printf "Pull Request already exists:\n%s\n" "$pr_url"
  else
    if has_github_workflow; then
      info "running local GitHub Action pull_request workflow with act"
      act pull_request --container-options "-v $HOME/.gitconfig:/root/.gitconfig:ro -v $SSH_AUTH_SOCK:/ssh-agent -e SSH_AUTH_SOCK=/ssh-agent"
    else
      info "no GitHub Action workflow found in .github/workflow; skipping act"
    fi

    info "creating Pull Request from '$branch' into '$base'"

    if [[ -n "$pr_title" ]]; then
      pr_url="$(
        gh pr create \
          --title "$pr_title" \
          --body "${pr_body}" \
          --base "$base" \
          --head "$branch" 
        )"
      else
        gh pr create \
          --base "$base" \
          --head "$branch" \
          --web=false
    fi

    printf "Pull Request created:\n%s\n" "$pr_url"
  fi
}
