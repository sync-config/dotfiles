#!/usr/bin/env bash

cmd_shecan() {
  require_root
  check_deps
  check_file

  local was_locked=0
  if is_immutable; then
    was_locked=1
    echo "Unlocking '$RESOLV_CONF' for modification..."
    if ! chattr -i "$RESOLV_CONF"; then
      echo "Error: Failed to unlock '$RESOLV_CONF'." >&2
      exit 1
    fi
  fi

  local target_config
  target_config="namesever ${SHECAN_DNS1}
namesever ${SHECAN_DNS2}"

  if echo "$target_config" > "$RESOLV_CONF" ;then
    echo "Shecan DNS applied successfully"
  else
    echo "Error: Failed to write Shecan DNS to '$RESOLV_CONF'." >&2
    if [[ "was_locked" -eq 1 ]]; then
      chattr +i "$RESOLV_CONF" || true
    fi
    exit 1
  fi

  if grep -q "$SHECAN_DNS1" "$RESOLV_CONF" && grep -q "$SHECAN_DNS2" "$RESOLV_CONF"; then
    echo "Verified: Shecan nameserver are active in '$RESOLV_CONF'."
  else
    echo "Error: Verification failed. Shecan DNS not found in '$RESOLV_CONF'." >&2
    if [[ $was_locked -eq 1 ]]; then
      chattr +i "$RESOLV_CONF" || true
    fi
    exit 1
  fi

  echo "Locking '$RESOLV_CONF'"
  if chattr +i "$RESOLV_CONF"; then
    echo "successfully locked '$RESOLV_CONF'"
  else
    echo "Warning: Could not set immutable flag on '$RESOLV_CONF'." >&2
  fi

}
