#!/usr/bin/env bash

cmd_start() {
  local -a fzf_out=()
  local query=""
  local selection=""
  local new_branch=""
  local response=""

  require_command fzf
  require_git_repo

  mapfile -t fzf_out < <(
    git branch --format='%(refname:short)' |
      fzf \
        --print-query \
        --height='80%' \
        --layout=reverse \
        --border \
        --prompt='Branch> ' \
        --preview '
    branch={}
    if [[ -n "$branch" ]]; then
      git log "$branch" -30 \
        --color=always \
        --date=short \
        --format="%C(yellow)%h%Creset %C(green)%ad%Creset %s %c(dim)-- %an%Creset"
    fi
    ' \
        --preview-window='right:65%:wrap'
    )

    query="${fzf_out[0]:-}"
    selection="${fzf_out[1]:-}"

    if [[ -n "$selection" ]]; then
      info "switching to branch '$selection'"
      git switch "$selection"
      nvim .
      return 
    fi

    if [[ -n "$query" ]]; then
        new_branch="$(
        printf '%s' "$query" |
          tr '[:space:]' '-' |
          tr -cd '[:alnum:]./_-'
        )"

        [[ -n "$new_branch" ]] ||
          die "the entered branch name is invalid"

        git check-ref-format --branch "$new_branch" >/dev/null 2>&1 ||
          die "'$new_branch' is not a valid Git branch name"

        if git show-ref --verify --quiet "refs/heads/$new_branch"; then
          info "branch '$new_branch' already exists"
          git switch "$new_branch"
          return 
        fi

        printf "Create branch '%s'? [y/N]:" "$new_branch"
        read -r response

        if [[ "$response" =~ ^[Yy]$ ]]; then
          git switch -c "$new_branch"
          nvim .
        else
          info "cancelled"
        fi
    fi
}
