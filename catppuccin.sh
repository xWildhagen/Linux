#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.shared/helpers.sh"

# ─── Configuration ──────────────────────────────────────────────────────────────

CATPPUCCIN_DIR="${HOME}/catppuccin"

AVAILABLE_PORTS=("kde")

# ─── Usage ──────────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
🐈‍⬛ Catppuccin Theme Installer for CachyOS

Usage: ./catppuccin.sh [OPTION]

Options:
  --help      Show this help message
  --all       Install all available ports
  --kde       Install the KDE Plasma theme

Available ports: ${AVAILABLE_PORTS[*]}
Clone directory: ${CATPPUCCIN_DIR}
EOF
}

# ─── Port: KDE ──────────────────────────────────────────────────────────────────

install_kde() {
    log_step "Installing Catppuccin KDE theme"

    local kde_dir="${CATPPUCCIN_DIR}/kde"
    local kde_repo="https://github.com/catppuccin/kde"

    # Dependencies required by the upstream install.sh
    ensure_dependencies git wget sed unzip

    # lookandfeeltool ships with plasma-workspace on KDE Plasma 6
    if ! command -v lookandfeeltool &> /dev/null; then
        log_warn "lookandfeeltool not found — make sure plasma-workspace is installed"
        log_info "Attempting to install plasma-workspace..."
        sudo pacman -S --noconfirm --needed plasma-workspace
    fi

    clone_or_pull "${kde_repo}" "${kde_dir}"

    log_info "Launching the Catppuccin KDE installer..."
    log_info "Follow the interactive prompts to choose flavor, accent, and window decoration."
    echo ""

    # Run the upstream install script from within its directory
    (cd "${kde_dir}" && bash ./install.sh)

    log_ok "Catppuccin KDE theme installation complete"
}

# ─── Dispatch ───────────────────────────────────────────────────────────────────

run_ports() {
    local ports=("$@")

    mkdir -p "${CATPPUCCIN_DIR}"
    log_info "Catppuccin directory: ${CATPPUCCIN_DIR}"

    for port in "${ports[@]}"; do
        local fn="install_${port}"
        if declare -f "${fn}" > /dev/null 2>&1; then
            "${fn}"
        else
            log_error "Unknown port: ${port}"
            return 1
        fi
    done

    log_ok "Done!"
}

main() {
    if [[ $# -eq 0 ]]; then
        usage
        return 0
    fi

    case "$1" in
        --all)
            run_ports "${AVAILABLE_PORTS[@]}"
            ;;
        --kde)
            run_ports "kde"
            ;;
        --help)
            usage
            ;;
        *)
            log_error "Unknown option: $1"
            echo ""
            usage
            return 1
            ;;
    esac
}

main "$@"
