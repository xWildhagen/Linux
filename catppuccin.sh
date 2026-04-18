#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.shared/helpers.sh"

# ─── Configuration ──────────────────────────────────────────────────────────────

CATPPUCCIN_DIR="${HOME}/catppuccin"

AVAILABLE_PORTS=("alacritty" "btop" "kde" "limine")

# ─── Usage ──────────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
🐈‍⬛ Catppuccin Theme Installer for CachyOS

Usage: ./catppuccin.sh [OPTION]

Options:
  --help       Show this help message
  --all        Install all available ports
  --alacritty  Install Catppuccin Mocha theme for Alacritty
  --btop       Install Catppuccin Mocha theme for btop
  --kde        Install the KDE Plasma theme
  --limine    Apply Catppuccin Mocha to the Limine bootloader

Available ports: ${AVAILABLE_PORTS[*]}
Clone directory: ${CATPPUCCIN_DIR}
EOF
}

# ─── Port: Alacritty ─────────────────────────────────────────────────────────────

install_alacritty() {
    log_step "Installing Catppuccin Mocha theme for Alacritty"

    local alacritty_repo_dir="${CATPPUCCIN_DIR}/alacritty"
    local alacritty_repo="https://github.com/catppuccin/alacritty"
    local alacritty_config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/alacritty"

    ensure_dependencies git alacritty

    clone_or_pull "${alacritty_repo}" "${alacritty_repo_dir}"

    mkdir -p "${alacritty_config_dir}"
    cp -f "${alacritty_repo_dir}/catppuccin-mocha.toml" "${alacritty_config_dir}/alacritty.toml"

    log_success "Catppuccin Mocha theme installed for Alacritty"
}

# ─── Port: btop ─────────────────────────────────────────────────────────────────

install_btop() {
    log_step "Installing Catppuccin Mocha theme for btop"

    local btop_dir="${CATPPUCCIN_DIR}/btop"
    local btop_repo="https://github.com/catppuccin/btop"
    local btop_themes_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/btop/themes"

    ensure_dependencies git btop

    clone_or_pull "${btop_repo}" "${btop_dir}"

    mkdir -p "${btop_themes_dir}"
    cp "${btop_dir}/themes/"*.theme "${btop_themes_dir}/"

    log_info "Installed themes to ${btop_themes_dir}/"
    log_info "Open btop → Esc → Options to select Catppuccin Mocha"
    log_success "Catppuccin btop themes installed"
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

    log_success "Catppuccin KDE theme installation complete"
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
    local -a search_roots=(/boot /boot/efi /efi /esp)

    local esp_mount
    esp_mount=$(findmnt -n -o TARGET -S PARTLABEL=EFI 2>/dev/null \
             || findmnt -n -o TARGET -t vfat /boot 2>/dev/null \
             || true)
    if [[ -n "${esp_mount}" ]]; then
        search_roots+=("${esp_mount}")
    fi

    local -a rel_paths=(
        "limine.conf"
        "limine/limine.conf"
        "boot/limine.conf"
        "boot/limine/limine.conf"
        "EFI/BOOT/limine.conf"
    )

    for root in "${search_roots[@]}"; do
        for rel in "${rel_paths[@]}"; do
            if sudo test -f "${root}/${rel}"; then
                limine_conf="${root}/${rel}"
                break 2
            fi
        done
    done

    if [[ -z "${limine_conf}" ]]; then
        log_error "Could not find limine.conf"
        log_info "Searched roots: ${search_roots[*]}"
        log_info "Run: sudo find / -name 'limine.conf' 2>/dev/null"
        log_info "Then prepend ${theme_path} manually"
        return 1
    fi

    log_info "Found config: ${limine_conf}"

    if sudo grep -q 'Catppuccin Mocha' "${limine_conf}" 2>/dev/null; then
        log_warn "Catppuccin Mocha theme already present in ${limine_conf}"
        log_info "Remove the existing theme block first if you want to re-apply"
        return 0
    fi

    log_info "Prepending ${theme_file} to ${limine_conf}"
    local tmp_conf
    tmp_conf=$(mktemp)
    cat "${theme_path}" <(sudo cat "${limine_conf}") > "${tmp_conf}"
    sudo cp "${tmp_conf}" "${limine_conf}"
    rm -f "${tmp_conf}"

    log_success "Catppuccin Mocha applied to Limine bootloader"
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

    log_success "Done!"
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
        --alacritty)
            run_ports "alacritty"
            ;;
        --btop)
            run_ports "btop"
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
