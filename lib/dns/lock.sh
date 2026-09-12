#!/usr/bin/env bash

cmd_lock() {
  require_root
  check_deps
  check_file

  if is_immutable; then
    echo "Notice: '$RESOLV_CONF' is already locked."
    return 0 
  fi

  if chattr +i "$RESOLV_CONF"; then
    echo "Successfully locked '$RESOLV_CONF' (+i)."
  else
    echo "Error: Failed to lock '$RESOLV_CONF'." >&2
    exit 1
  fi
}

cmd_unlock() {
  require_root
  check_deps
  check_file

  if ! is_immutable ; then
    echo "Notice: '$RESOLV_CONF' is already unlocked "
    return 0
  fi

  if chattr -i "$RESOLV_CONF" ; then
    echo "Successfully unlocked '$RESOLV_CONF' (-i)."
  else
    echo "Error: Failed to unlock '$RESOLV_CONF'." >&2
    exit 1
  fi
}
