#!/usr/bin/env bash

# Prefix for temporary lab directories
LAB_PREFIX="${LAB_PREFIX:-lab}"

# Default temporary storage
# You can later override this in ~/.config/lab/config.sh
LAB_BASE_DIR="${LAB_BASE_DIR:-${TMPDIR:-/tmp}}"

# The interactive shell used inside the lab.
LAB_SHELL="${LAB_SHELL:-${SHELL:-/usr/bin/bash}}"

# Optional personal override.
USER_CONFIG="${HOME}/.config/lab/config.sh"

if [[ -f "$USER_CONFIG" ]]; then
  # shellcheck source=/dev/null
  source "$USER_CONFIG"
fi
