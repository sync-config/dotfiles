#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

read_packages() {
    local file="$1"

    sed \
        -e 's/[[:space:]]*#.*$//' \
        -e '/^[[:space:]]*$/d' \
        "$file"
}

detect_distro() {
    # shellcheck disable=SC1091
    . /etc/os-release

    case "${ID:-}" in
        arch)
            echo "arch"
            ;;
        debian|ubuntu|linuxmint|pop)
            echo "debian"
            ;;
        *)
            echo "Unsupported distro: ${ID:-unknown}" >&2
            exit 1
            ;;
    esac
}

install_arch() {
    local packages=()

    mapfile -t packages < <(
        read_packages "$DOTFILES/packages/arch.txt"
    )

    sudo pacman -Syu --needed "${packages[@]}"
}

install_debian() {
    local packages=()

    mapfile -t packages < <(
        read_packages "$DOTFILES/packages/debian.txt"
    )

    sudo apt-get update
    sudo apt-get install -y "${packages[@]}"
}

main() {
    case "$(detect_distro)" in
        arch)
            install_arch
            ;;
        debian)
            install_debian
            ;;
    esac
}

main "$@"

