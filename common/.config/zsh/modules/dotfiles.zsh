export DOTFILES="$HOME/.dotfiles"

alias dotfiles='git -C "$DOTFILES"'
alias dotstatus='git -C "$DOTFILES" status'
alias dotdiff='git -C "$DOTFILES" diff'
alias dotlog='git -C "$DOTFILES" log --oneline --decorate -10'



dotapply() {
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

dotsave() {
    local message="${*:-dotfiles: update}"

    git -C "$DOTFILES" add -A &&
        git -C "$DOTFILES" commit -m "$message" &&
        git -C "$DOTFILES" push
}

dotupdate() {
    dotsync || return 1
    dotinstall || return 1

    if command -v nvim >/dev/null 2>&1; then
        nvim --headless "+Lazy! sync" +qa
    fi
}

