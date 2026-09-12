#!/usr/bin/env bash

RESOLV_CONF="/etc/resolv.conf"

check_file() {
  if [[ ! -f "$RESOLV_CONF" ]]; then
    echo "Error '$RESOLV_CONF' does not exist."
    exit 1
  fi
}

check_deps() {
  local cmd
  for cmd in lsattr chattr; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "Error: Required command '$cmd' is not installed or not in PATH." >&2
      exit 1
    fi
  done

}

is_immutable() {
  check_deps
  check_file
  lsattr -d "$RESOLV_CONF" 2>/dev/null | awk '{print $1}' | grep -q "i"
}
