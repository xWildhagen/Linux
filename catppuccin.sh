#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.shared/helpers.sh"

# ─── Configuration ──────────────────────────────────────────────────────────────

CATPPUCCIN_DIR="${HOME}/catppuccin"

AVAILABLE_PORTS=("kde" "limine")

# ─── Usage ──────────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
🐈‍⬛ Catppuccin Theme Installer for CachyOS

Usage: ./catppuccin.sh [OPTION]

Options:
  --help      Show this help message
  --all       Install all available ports
  --kde       Install the KDE Plasma theme
  --limine    Apply Catppuccin Mocha to the Limine bootloader

Available ports: ${AVAILABLE_PORTS[*]}
Clone directory: ${CATPPUCCIN_DIR}
EOF
}

# ─── Port: KDE ──────────────────────────────────────────────────────────────────

install_kde() {
    log_step "Installing Catppuccin KDE theme"

    local kde_dir="${CATPPUCCIN_DIR}/kde"
    local kde_repo="https://github.com/catppuccin/kde"

    ensure_dependencies git wget sed unzip

    if ! command -v lookandfeeltool &> /dev/null; then
        log_warn "lookandfeeltool not found — make sure plasma-workspace is installed"
        log_info "Attempting to install plasma-workspace..."
        sudo pacman -S --noconfirm --needed plasma-workspace
    fi

    clone_or_pull "${kde_repo}" "${kde_dir}"

    log_info "Launching the Catppuccin KDE installer..."
    log_info "Follow the interactive prompts to choose flavor, accent, and window decoration."
    echo ""

    (cd "${kde_dir}" && bash ./install.sh)

    log_ok "Catppuccin KDE theme installation complete"
}

# ─── Port: Limine ───────────────────────────────────────────────────────────────

install_limine() {
    log_step "Installing Catppuccin Mocha theme for Limine bootloader"

    local limine_dir="${CATPPUCCIN_DIR}/limine"
    local limine_repo="https://github.com/catppuccin/limine"
    local theme_file="catppuccin-mocha.conf"

    ensure_dependencies git

    clone_or_pull "${limine_repo}" "${limine_dir}"

    local theme_path="${limine_dir}/themes/${theme_file}"
    if [[ ! -f "${theme_path}" ]]; then
        log_error "Theme file not found: ${theme_path}"
        return 1
    fi

    local limine_conf=""
    for candidate in /boot/limine.conf /boot/efi/limine.conf /efi/limine.conf; do
        if [[ -f "${candidate}" ]]; then
            limine_conf="${candidate}"
            break
        fi
    done

    if [[ -z "${limine_conf}" ]]; then
        log_error "Could not find limine.conf in /boot or /boot/efi"
        log_info "If your limine.conf is elsewhere, prepend ${theme_path} manually"
        return 1
    fi

    log_info "Found config: ${limine_conf}"

    if grep -q 'Catppuccin Mocha' "${limine_conf}" 2>/dev/null; then
        log_warn "Catppuccin Mocha theme already present in ${limine_conf}"
        log_info "Remove the existing theme block first if you want to re-apply"
        return 0
    fi

    local backup="${limine_conf}.bak.$(date +%Y%m%d%H%M%S)"
    log_info "Backing up to ${backup}"
    sudo cp "${limine_conf}" "${backup}"

    log_info "Prepending ${theme_file} to ${limine_conf}"
    local tmp_conf
    tmp_conf=$(mktemp)
    cat "${theme_path}" "${limine_conf}" > "${tmp_conf}"
    sudo cp "${tmp_conf}" "${limine_conf}"
    rm -f "${tmp_conf}"

    log_ok "Catppuccin Mocha applied to Limine bootloader"
    log_info "Reboot to see the themed boot menu"
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
        --limine)
            run_ports "limine"
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
