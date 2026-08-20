precmd() {
  vcs_info
  check_virtualenv

  RPROMPT_PARTS=()

  if [[ -n "$vcs_info_msg_0_" ]]; then
    RPROMPT_PARTS+=("%F{238}%f%F{0}%K{238}  ${vcs_info_msg_0_} %f")
  fi

  if [[ -n "$VENV_PROMPT" ]]; then
    RPROMPT_PARTS+=("%F{245}%f%F{0}%K{245}  ${VENV_PROMPT} %f")
  fi

  # Show an indicator only inside a disposable `lab` session.
  if [[ "${LAB_ACTIVE:-}" == "1" ]]; then
    RPROMPT_PARTS+=("%F{245}%f%F{0}%K{245} ⚗️ ${LAB_TOPIC} %f")
  fi

  RPROMPT="${(j: :)RPROMPT_PARTS}"
}
