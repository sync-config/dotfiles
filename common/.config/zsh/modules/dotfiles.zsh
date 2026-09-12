export DOTFILES="$HOME/.dotfiles"

alias dotfiles='git -C "$DOTFILES"'
alias dotstatus='git -C "$DOTFILES" status'
alias dotdiff='git -C "$DOTFILES" diff'
alias dotlog='git -C "$DOTFILES" log --oneline --decorate -10'

link_binaries() {
  local dotfiles_bin="$DOTFILES/bin"
  local target_dir="/usr/local/bin"

  echo "Linking system-wide binaries to $target_dir..."
  
  for script in "$dotfiles_bin"/*; do
    if [[ -f "$script" && -x "$script" ]]; then
      local name="$(basename "$script")"
      sudo ln -sf "$script" "$target_dir/$name"
    fi
  done
}

dotapply() {
    link_binaries
    stow \
        --dir="$DOTFILES" \
        --target="$HOME" \
        --restow \
        common

}

dotinstall() {
    "$DOTFILES/setup/install-packages.sh"
}

dotsync() {
    git -C "$DOTFILES" pull --ff-only || return 1
    dotapply
}

dotupdate() {
    dotsync || return 1
    dotinstall || return 1

    if command -v nvim >/dev/null 2>&1; then
        nvim --headless "+Lazy! sync" +qa
    fi
}
