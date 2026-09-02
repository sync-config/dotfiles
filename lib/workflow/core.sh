#!/usr/bin/env bash

die() {
  printf 'flow: error: %s\n' "$*" >&2
  exit 1
}

info() {
  printf 'flow: %s\n' "$*"
}

warning() {
  printf 'flow: warning: %s\n' "$*" >&2
}

require_command() {
  command -v "$1" >/dev/null 2>&1 ||
    die "require command '$1' is not installed"
}
