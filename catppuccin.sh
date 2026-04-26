#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.shared/helpers.sh"

# ─── Configuration ──────────────────────────────────────────────────────────────

CATPPUCCIN_DIR="${HOME}/catppuccin"

AVAILABLE_PORTS=("alacritty" "btop" "kde" "konsole" "limine" "lxqt" "micro" "mpv" "qt5ct" "qtcreator" "qterminal" "vim")

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
  --kde        Install Catppuccin Mocha theme for KDE Plasma
  --konsole    Install Catppuccin Mocha theme for Konsole
  --limine     Install Catppuccin Mocha theme for Limine
  --lxqt       Install Catppuccin Mocha theme for LXQt
  --micro      Install Catppuccin Mocha theme for micro
  --mpv        Install Catppuccin Mocha theme for mpv
  --qt5ct      Install Catppuccin Mocha theme for qt5ct/qt6ct
  --qtcreator  Install Catppuccin Mocha theme for Qt Creator
  --qterminal  Install Catppuccin Mocha theme for QTerminal
  --vim        Install Catppuccin Mocha theme for Vim

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

# ─── Port: Konsole ──────────────────────────────────────────────────────────────

install_konsole() {
    log_step "Installing Catppuccin Mocha theme for Konsole"

    local konsole_repo_dir="${CATPPUCCIN_DIR}/konsole"
    local konsole_repo="https://github.com/catppuccin/konsole"
    local konsole_data_dir="${HOME}/.local/share/konsole"

    ensure_dependencies git konsole

    clone_or_pull "${konsole_repo}" "${konsole_repo_dir}"

    mkdir -p "${konsole_data_dir}"
    cp -f "${konsole_repo_dir}/themes/catppuccin-mocha.colorscheme" "${konsole_data_dir}/"

    log_info "Installed colorscheme to ${konsole_data_dir}/"
    log_info "Reload Konsole → Settings → Manage Profiles → Appearance to select Catppuccin Mocha"
    log_success "Catppuccin Mocha theme installed for Konsole"
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

# ─── Port: LXQt ─────────────────────────────────────────────────────────────────

install_lxqt() {
    log_step "Installing Catppuccin Mocha theme for LXQt"

    local lxqt_repo_dir="${CATPPUCCIN_DIR}/lxqt"
    local lxqt_repo="https://github.com/catppuccin/lxqt"
    local lxqt_themes_dir="/usr/share/lxqt/themes"

    ensure_dependencies git

    clone_or_pull "${lxqt_repo}" "${lxqt_repo_dir}"

    if [[ ! -d "${lxqt_repo_dir}/src/catppuccin-mocha" ]]; then
        log_error "Theme directory not found: ${lxqt_repo_dir}/src/catppuccin-mocha"
        return 1
    fi

    sudo mkdir -p "${lxqt_themes_dir}"
    sudo cp -rf "${lxqt_repo_dir}/src/catppuccin-mocha" "${lxqt_themes_dir}/"

    log_info "Installed theme to ${lxqt_themes_dir}/catppuccin-mocha/"
    log_info "Go to Appearance → Theme → select Catppuccin Mocha"
    log_success "Catppuccin Mocha theme installed for LXQt"
}

# ─── Port: micro ────────────────────────────────────────────────────────────────

install_micro() {
    log_step "Installing Catppuccin Mocha theme for micro editor"

    local micro_repo_dir="${CATPPUCCIN_DIR}/micro"
    local micro_repo="https://github.com/catppuccin/micro"
    local micro_colors_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/micro/colorschemes"

    ensure_dependencies git micro

    clone_or_pull "${micro_repo}" "${micro_repo_dir}"

    mkdir -p "${micro_colors_dir}"
    cp -f "${micro_repo_dir}/themes/catppuccin-mocha.micro" "${micro_colors_dir}/"

    log_info "Installed colorscheme to ${micro_colors_dir}/"
    log_info "Ensure MICRO_TRUECOLOR=1 is exported in your shell RC file"
    log_info "In micro: Ctrl+e → set colorscheme catppuccin-mocha"
    log_success "Catppuccin Mocha theme installed for micro"
}

# ─── Port: mpv ──────────────────────────────────────────────────────────────────

install_mpv() {
    log_step "Installing Catppuccin Mocha theme for mpv"

    local mpv_repo_dir="${CATPPUCCIN_DIR}/mpv"
    local mpv_repo="https://github.com/catppuccin/mpv"
    local mpv_config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/mpv"
    local accent="lavender"
    local theme_file="themes/mocha/${accent}.conf"

    ensure_dependencies git mpv

    clone_or_pull "${mpv_repo}" "${mpv_repo_dir}"

    local theme_path="${mpv_repo_dir}/${theme_file}"
    if [[ ! -f "${theme_path}" ]]; then
        log_error "Theme file not found: ${theme_path}"
        return 1
    fi

    mkdir -p "${mpv_config_dir}"
    cp -f "${theme_path}" "${mpv_config_dir}/mpv.conf"

    log_info "Installed ${accent} accent from Mocha flavor"
    log_success "Catppuccin Mocha theme installed for mpv"
}

# ─── Port: qt5ct ────────────────────────────────────────────────────────────────

install_qt5ct() {
    log_step "Installing Catppuccin Mocha theme for qt5ct/qt6ct"

    local qt5ct_repo_dir="${CATPPUCCIN_DIR}/qt5ct"
    local qt5ct_repo="https://github.com/catppuccin/qt5ct"
    local accent="mauve"
    local theme_file="catppuccin-mocha-${accent}.conf"
    local qt5ct_colors_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/qt5ct/colors"
    local qt6ct_colors_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/qt6ct/colors"

    ensure_dependencies git

    clone_or_pull "${qt5ct_repo}" "${qt5ct_repo_dir}"

    local theme_path="${qt5ct_repo_dir}/themes/${theme_file}"
    if [[ ! -f "${theme_path}" ]]; then
        log_error "Theme file not found: ${theme_path}"
        return 1
    fi

    mkdir -p "${qt5ct_colors_dir}" "${qt6ct_colors_dir}"
    cp -f "${theme_path}" "${qt5ct_colors_dir}/"
    cp -f "${theme_path}" "${qt6ct_colors_dir}/"

    log_info "Installed ${accent} accent to qt5ct and qt6ct colors"
    log_info "Open qt5ct/qt6ct → set palette to Custom → select catppuccin-mocha-${accent}"
    log_success "Catppuccin Mocha theme installed for qt5ct/qt6ct"
}

# ─── Port: Qt Creator ───────────────────────────────────────────────────────────

install_qtcreator() {
    log_step "Installing Catppuccin Mocha theme for Qt Creator"

    local qtcreator_repo_dir="${CATPPUCCIN_DIR}/qtcreator"
    local qtcreator_repo="https://github.com/catppuccin/qtcreator"
    local qtcreator_config_dir="${XDG_CONFIG_HOME:-${HOME}/.config}/QtProject/qtcreator"
    local qtcreator_styles_dir="${qtcreator_config_dir}/styles"
    local qtcreator_themes_dir="${qtcreator_config_dir}/themes"

    ensure_dependencies git

    clone_or_pull "${qtcreator_repo}" "${qtcreator_repo_dir}"

    mkdir -p "${qtcreator_styles_dir}" "${qtcreator_themes_dir}"
    cp -f "${qtcreator_repo_dir}/styles/catppuccin-mocha.xml" "${qtcreator_styles_dir}/"
    cp -f "${qtcreator_repo_dir}/themes/catppuccin-mocha.creatortheme" "${qtcreator_themes_dir}/"

    log_info "Installed style and theme to ${qtcreator_config_dir}/"
    log_info "Edit → Preferences → Environment → Theme → catppuccin-mocha"
    log_success "Catppuccin Mocha theme installed for Qt Creator"
}

# ─── Port: QTerminal ────────────────────────────────────────────────────────────

install_qterminal() {
    log_step "Installing Catppuccin Mocha theme for QTerminal"

    local qterminal_repo_dir="${CATPPUCCIN_DIR}/qterminal"
    local qterminal_repo="https://github.com/catppuccin/qterminal"
    local color_schemes_dir="/usr/share/qtermwidget5/color-schemes"

    ensure_dependencies git qterminal

    clone_or_pull "${qterminal_repo}" "${qterminal_repo_dir}"

    if [[ ! -d "${color_schemes_dir}" ]]; then
        log_warn "Color schemes directory not found: ${color_schemes_dir}"
        log_info "Creating directory..."
        sudo mkdir -p "${color_schemes_dir}"
    fi

    sudo cp -f "${qterminal_repo_dir}/src/Catppuccin-Mocha.colorscheme" "${color_schemes_dir}/"

    log_info "Installed colorscheme to ${color_schemes_dir}/"
    log_info "Open QTerminal → File → Preferences → Appearance → Color scheme to select Catppuccin-Mocha"
    log_success "Catppuccin Mocha theme installed for QTerminal"
}

# ─── Port: Vim ──────────────────────────────────────────────────────────────────

install_vim() {
    log_step "Installing Catppuccin Mocha theme for Vim"

    local vim_repo="https://github.com/catppuccin/vim"
    local vim_pack_dir="${HOME}/.vim/pack/catppuccin/start/catppuccin"
    local vimrc="${HOME}/.vimrc"

    ensure_dependencies git vim

    clone_or_pull "${vim_repo}" "${vim_pack_dir}"

    # Ensure termguicolors and colorscheme are set in .vimrc
    touch "${vimrc}"

    if ! grep -q 'set termguicolors' "${vimrc}"; then
        echo 'set termguicolors' >> "${vimrc}"
        log_info "Added 'set termguicolors' to ${vimrc}"
    fi

    if ! grep -q 'colorscheme catppuccin_mocha' "${vimrc}"; then
        echo 'colorscheme catppuccin_mocha' >> "${vimrc}"
        log_info "Added 'colorscheme catppuccin_mocha' to ${vimrc}"
    fi

    log_success "Catppuccin Mocha theme installed for Vim"
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
        --konsole)
            run_ports "konsole"
            ;;
        --limine)
            run_ports "limine"
            ;;
        --lxqt)
            run_ports "lxqt"
            ;;
        --micro)
            run_ports "micro"
            ;;
        --mpv)
            run_ports "mpv"
            ;;
        --qt5ct)
            run_ports "qt5ct"
            ;;
        --qtcreator)
            run_ports "qtcreator"
            ;;
        --qterminal)
            run_ports "qterminal"
            ;;
        --vim)
            run_ports "vim"
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
