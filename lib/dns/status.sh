#!/usr/bin/env bash

cmd_status() {
  check_file
  echo "=== Current DNS Configuration ($RESOLV_CONF) ==="
  echo "$RESOLV_CONF"
  echo "===================================================="

  if command -v lsattr >/dev/null 2>&1; then

    if is_immutable ;then
      echo "Immutable status: LOCKED (immutable flag is set)"
    else
      echo "Immutable status: UNLOKED (writable)"
    fi

  else
    echo "Immutable status: Unknown (lsattr not found)"

  fi
}
