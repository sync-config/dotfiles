#!/usr/bin/env bash


lab_info() {
  printf '\033[1;34m[lab]\033[0m %s\n' "$*"
}

lab_warn() {
  printf '\033[1;33m[lab]\033[0m %s\n' "$*" >&2
}

lab_error() {
  printf '\033[1;31m[lab]\033[0m %s\n' "$*" >&2
}

lab_die() {
  lab_error "$*"
  exit 1
}


lab_usage() {
  cat << 'EOF'
Usage: 
  lab: <topic>

Create a temporary git worktree from the current repository.

Arguments:
  <topic>  A short label describing your experiment

Example:
  lab ci-local
  lab github-action
  lab pre-commit-hooks
  lab alembic-upgrade
  lab react-upgrade

Enviroment:
  LAB_BASE_DIR  where temporary session are created.
  LAB_SHELL     Shell used inside the lab.

EOF
}
