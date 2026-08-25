#!/usr/bin/env bash

parse_args() {
  if [[ $# -eq 0 ]]; then
    lab_usage
    exit 1
  fi

  case "${1:-}" in
    -h|--help)
      lab_usage
      exit 0
      ;;
  esac

  if [[ $# -ne 1 ]]; then
    lab_die "expected exactly one argument: <topic>"
  fi

  LAB_TOPIC="$1"

  # Safe and readable directory name:
  # "CI test / Actions!" -> "CI-test-actions-"
  LAB_SAFE_TOPIC="$(
    printf '%s' "$LAB_TOPIC" \
      | tr -cs '[:alnum:]._-' '-' \
      | tr ' ' '-'
    )"

    [[ -n "$LAB_SAFE_TOPIC" ]] || lab_die "topic is invalid"
}


