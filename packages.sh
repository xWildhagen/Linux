#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.shared/helpers.sh"

# ─── Configuration ──────────────────────────────────────────────────────────────

# Packages to install (both official repositories and AUR)
PACKAGES=(
    "git"
    "base-devel"
    "wget"
    "curl"
    "vim"
    "htop"
    "microsoft-edge-stable-bin"
    "visual-studio-code-bin"
    "antigravity-ide"
    "antigravity-cli"
    "moonlight-qt-bin"
    "rclone"
)

# ─── Helper Functions ───────────────────────────────────────────────────────────

# Find available AUR helper
get_aur_helper() {
    if command -v yay &> /dev/null; then
        echo "yay"
    elif command -v paru &> /dev/null; then
        echo "paru"
    else
        echo ""
    fi
}

# ─── Usage ──────────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
📦 CachyOS Package Installer

Usage: ./packages.sh [OPTION]

Options:
  --help         Show this help message
  --install      Install all defined packages
  --all          Install all defined packages (alias for --install)

Configuration:
  Defined packages: ${#PACKAGES[@]}
EOF
}

# ─── Installation Functions ─────────────────────────────────────────────────────

install_packages() {
    log_step "Resolving and installing packages... ⏳"

    if [[ -z "${PACKAGES+x}" || ${#PACKAGES[@]} -eq 0 ]]; then
        log_info "No packages defined in the list. ℹ️"
        return 0
    fi

    local pacman_pkgs=()
    local aur_pkgs=()

    log_step "Categorizing packages (Official vs AUR)... ⏳"
    for pkg in "${PACKAGES[@]}"; do
        # -Si checks sync db for individual packages, -Sg checks for package groups
        if pacman -Si "${pkg}" &> /dev/null || pacman -Sg "${pkg}" &> /dev/null; then
            pacman_pkgs+=("${pkg}")
        else
            aur_pkgs+=("${pkg}")
        fi
    done

    if [[ ${#pacman_pkgs[@]} -gt 0 ]]; then
        log_step "Installing official pacman packages... ⏳"
        sudo pacman -S --noconfirm --needed "${pacman_pkgs[@]}"
        log_success "Pacman packages installed successfully ✅"
    fi

    if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
        log_step "Installing AUR packages... ⏳"
        local aur_helper
        aur_helper=$(get_aur_helper)

        if [[ -z "${aur_helper}" ]]; then
            log_warn "No AUR helper (yay or paru) found. The following AUR packages were not installed: ⚠️"
            for pkg in "${aur_pkgs[@]}"; do
                log_warn "  - ${pkg}"
            done
            return 1
        fi

        log_info "Using AUR helper: ${aur_helper} ℹ️"
        # Never prefix AUR helpers like yay or paru with sudo
        "${aur_helper}" -S --noconfirm --needed "${aur_pkgs[@]}"
        log_success "AUR packages installed successfully ✅"
    fi
}

# ─── Main ───────────────────────────────────────────────────────────────────────

main() {
    if [[ $# -eq 0 ]]; then
        usage
        return 0
    fi

    case "$1" in
        --all|--install)
            install_packages
            log_success "All packages installed! 🎉"
            ;;
        --help)
            usage
            ;;
        *)
            log_error "Unknown option: $1 ❌"
            echo ""
            usage
            return 1
            ;;
    esac
}

main "$@"
