cmd_status() {
  require_git_repo

  printf 'Repository: %s\n' "$(git rev-parse --show-toplevel)"
  printf 'Branch:     %s\n' "$(git branch --show-current)"
  printf '\n'

  git status --short --branch
}
