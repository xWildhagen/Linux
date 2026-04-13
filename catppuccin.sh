#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.shared/helpers.sh"

# ─── Configuration ──────────────────────────────────────────────────────────────

CATPPUCCIN_DIR="${HOME}/catppuccin"

AVAILABLE_PORTS=("kde" "login-manager")

# ─── Usage ──────────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
🐈‍⬛ Catppuccin Theme Installer for CachyOS

Usage: ./catppuccin.sh [OPTION]

Options:
  --help            Show this help message
  --all             Install all available ports
  --kde             Install the KDE Plasma theme
  --login-manager   Apply Catppuccin Mocha to Plasma Login Manager

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

# ─── Port: Plasma Login Manager ─────────────────────────────────────────────────

install_login-manager() {
    log_step "Applying Catppuccin Mocha to Plasma Login Manager"

    local user_color_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/color-schemes"
    local system_color_dir="/usr/share/color-schemes"
    local user_kdeglobals="${HOME}/.config/kdeglobals"
    local greeter_data_dir="/var/lib/plasmalogin"

    local color_file=""
    if [[ -d "${user_color_dir}" ]]; then
        color_file=$(find "${user_color_dir}" -maxdepth 1 -name 'CatppuccinMocha*.colors' -print -quit 2>/dev/null || true)
    fi

    if [[ -z "${color_file}" ]]; then
        log_warn "No CatppuccinMocha color scheme found in ${user_color_dir}"
        log_info "Run './catppuccin.sh --kde' first and choose Mocha as the flavor"
        return 1
    fi

    local color_basename
    color_basename=$(basename "${color_file}")
    log_info "Found color scheme: ${color_basename}"

    log_info "Installing color scheme to ${system_color_dir}/"
    sudo cp "${color_file}" "${system_color_dir}/${color_basename}"

    if [[ -f "${user_kdeglobals}" ]]; then
        log_info "Syncing kdeglobals to ${greeter_data_dir}/"
        sudo mkdir -p "${greeter_data_dir}"
        sudo cp "${user_kdeglobals}" "${greeter_data_dir}/kdeglobals"
    else
        log_warn "No kdeglobals found at ${user_kdeglobals}"
        log_info "Apply the Catppuccin theme to your desktop first, then re-run this"
        return 1
    fi

    sudo cp "${color_file}" "${greeter_data_dir}/${color_basename}"

    log_ok "Catppuccin Mocha applied to Plasma Login Manager"
    log_info "Reboot to see the changes on the login screen"
    log_info "You can also apply via: System Settings → Login Screen → Apply Plasma Settings"
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
        --login-manager)
            run_ports "login-manager"
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
