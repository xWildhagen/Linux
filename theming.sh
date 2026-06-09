#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.shared/helpers.sh"

# ─── Configuration ──────────────────────────────────────────────────────────────

CATPPUCCIN_DIR="${HOME}/catppuccin"
WALLPAPER_PATH="${SCRIPT_DIR}/.assets/aurora.png"

AVAILABLE_PORTS=("alacritty" "btop" "kde" "konsole" "limine" "lockscreen" "loginscreen" "micro" "mpv" "vim" "wallpaper")

# ─── Usage ──────────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
🐈‍⬛ Catppuccin Theme & CachyOS Theming Installer

Usage: ./catppuccin.sh [OPTION]

Options:
  --help         Show this help message
  --all          Install all available ports/themes
  --alacritty    Install Catppuccin Mocha theme for Alacritty
  --btop         Install Catppuccin Mocha theme for btop
  --kde          Install Catppuccin Mocha theme for KDE Plasma
  --konsole      Install Catppuccin Mocha theme for Konsole
  --limine       Install Catppuccin Mocha theme for Limine
  --lockscreen   Set CachyOS lockscreen to aurora.png
  --loginscreen  Set CachyOS login screen (SDDM) to aurora.png
  --micro        Install Catppuccin Mocha theme for micro
  --mpv          Install Catppuccin Mocha theme for mpv
  --vim          Install Catppuccin Mocha theme for Vim
  --wallpaper    Set CachyOS wallpaper to aurora.png

Available ports: ${AVAILABLE_PORTS[*]}
Clone directory: ${CATPPUCCIN_DIR}
Wallpaper path:  ${WALLPAPER_PATH}
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

# ─── Port: Lockscreen ──────────────────────────────────────────────────────────

install_lockscreen() {
    log_step "Setting CachyOS lockscreen 🖼️"

    if [[ ! -f "${WALLPAPER_PATH}" ]]; then
        log_error "Wallpaper file not found: ${WALLPAPER_PATH} ❌"
        return 1
    fi

    log_info "Applying lockscreen from ${WALLPAPER_PATH} ⏳"

    if command -v kwriteconfig6 &> /dev/null; then
        kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "${WALLPAPER_PATH}" || { log_error "Failed to apply lockscreen wallpaper for KDE Plasma 6 ❌"; return 1; }
        log_success "Successfully applied lockscreen wallpaper for KDE Plasma 6 ✅"
    elif command -v kwriteconfig5 &> /dev/null; then
        kwriteconfig5 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "${WALLPAPER_PATH}" || { log_error "Failed to apply lockscreen wallpaper for KDE Plasma 5 ❌"; return 1; }
        log_success "Successfully applied lockscreen wallpaper for KDE Plasma 5 ✅"
    elif command -v gsettings &> /dev/null && [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]]; then
        gsettings set org.gnome.desktop.screensaver picture-uri "file://${WALLPAPER_PATH}" || { log_error "Failed to apply lockscreen wallpaper for GNOME ❌"; return 1; }
        log_success "Successfully applied lockscreen wallpaper for GNOME ✅"
    else
        log_error "No supported lockscreen setter found for the current desktop environment ❌"
        return 1
    fi

    return 0
}

# ─── Port: Login Screen ────────────────────────────────────────────────────────

install_loginscreen() {
    log_step "Setting CachyOS login screen (SDDM) 🖼️"

    if [[ ! -f "${WALLPAPER_PATH}" ]]; then
        log_error "Wallpaper file not found: ${WALLPAPER_PATH} ❌"
        return 1
    fi

    if ! command -v sddm &> /dev/null && [[ ! -d /usr/share/sddm ]]; then
        log_error "SDDM does not appear to be installed or running ❌"
        return 1
    fi

    local target_dir="/usr/share/backgrounds"
    local target_wallpaper="${target_dir}/cachyos-custom-login.png"

    log_info "Copying wallpaper to ${target_dir} for SDDM access ⏳"
    sudo mkdir -p "${target_dir}" || { log_error "Failed to create ${target_dir} ❌"; return 1; }
    sudo cp "${WALLPAPER_PATH}" "${target_wallpaper}" || { log_error "Failed to copy wallpaper for SDDM ❌"; return 1; }
    sudo chmod 644 "${target_wallpaper}" || { log_error "Failed to set permissions for SDDM wallpaper ❌"; return 1; }

    # Detect current SDDM theme
    local sddm_theme=""
    
    # Check configurations, later files override earlier ones
    for conf_file in /etc/sddm.conf /etc/sddm.conf.d/*.conf; do
        if [[ -f "${conf_file}" ]]; then
            local extracted_theme
            extracted_theme=$(grep -E '^Current=' "${conf_file}" | tail -n1 | cut -d'=' -f2 || true)
            if [[ -n "${extracted_theme}" ]]; then
                sddm_theme="${extracted_theme}"
            fi
        fi
    done

    # Fallback to CachyOS default or breeze if none found
    if [[ -z "${sddm_theme}" ]]; then
        if [[ -d "/usr/share/sddm/themes/cachyos" ]]; then
            sddm_theme="cachyos"
        elif [[ -d "/usr/share/sddm/themes/breeze" ]]; then
            sddm_theme="breeze"
        else
            log_error "Could not determine SDDM theme ❌"
            return 1
        fi
    fi

    log_info "Applying login screen wallpaper to SDDM theme: ${sddm_theme} ⏳"

    local theme_dir="/usr/share/sddm/themes/${sddm_theme}"
    if [[ ! -d "${theme_dir}" ]]; then
        log_error "SDDM theme directory not found: ${theme_dir} ❌"
        return 1
    fi

    local theme_conf_user="${theme_dir}/theme.conf.user"
    echo -e "[General]\nbackground=${target_wallpaper}\ntype=image" | sudo tee "${theme_conf_user}" > /dev/null || { log_error "Failed to update SDDM theme config ❌"; return 1; }

    # Bulletproof fallback: Overwrite the theme's default background image directly
    # This ensures the wallpaper changes even if the theme ignores theme.conf.user overrides
    local default_bg
    default_bg=$(grep -E '^[bB]ackground=' "${theme_dir}/theme.conf" 2>/dev/null | tail -n1 | cut -d'=' -f2 | tr -d ' ' || true)
    
    if [[ -n "${default_bg}" ]]; then
        # Handle relative paths within the theme directory
        if [[ "${default_bg}" != /* ]]; then
            default_bg="${theme_dir}/${default_bg}"
        fi
        
        # If the file exists, overwrite it with our wallpaper
        if [[ -f "${default_bg}" ]]; then
            log_info "Overwriting default theme background at ${default_bg} as fallback ⏳"
            sudo cp "${WALLPAPER_PATH}" "${default_bg}" || true
            sudo chmod 644 "${default_bg}" || true
        fi
    fi

    log_success "Successfully applied login screen wallpaper for SDDM ✅"
    log_info "Note: You may need to logout or reboot to see the SDDM changes. ℹ️"
    return 0
}

# ─── Port: Wallpaper ───────────────────────────────────────────────────────────

install_wallpaper() {
    log_step "Setting CachyOS wallpaper 🖼️"

    if [[ ! -f "${WALLPAPER_PATH}" ]]; then
        log_error "Wallpaper file not found: ${WALLPAPER_PATH} ❌"
        return 1
    fi

    log_info "Applying wallpaper from ${WALLPAPER_PATH} ⏳"

    if command -v plasma-apply-wallpaperimage &> /dev/null; then
        plasma-apply-wallpaperimage "${WALLPAPER_PATH}" || { log_error "Failed to apply wallpaper for KDE Plasma ❌"; return 1; }
        log_success "Successfully applied wallpaper for KDE Plasma ✅"
    elif command -v gsettings &> /dev/null && [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]]; then
        gsettings set org.gnome.desktop.background picture-uri "file://${WALLPAPER_PATH}" || { log_error "Failed to apply wallpaper for GNOME ❌"; return 1; }
        gsettings set org.gnome.desktop.background picture-uri-dark "file://${WALLPAPER_PATH}" || { log_error "Failed to apply dark wallpaper for GNOME ❌"; return 1; }
        log_success "Successfully applied wallpaper for GNOME ✅"
    elif command -v feh &> /dev/null; then
        feh --bg-fill "${WALLPAPER_PATH}" || { log_error "Failed to apply wallpaper using feh ❌"; return 1; }
        log_success "Successfully applied wallpaper using feh ✅"
    elif command -v swww &> /dev/null; then
        swww img "${WALLPAPER_PATH}" || { log_error "Failed to apply wallpaper using swww ❌"; return 1; }
        log_success "Successfully applied wallpaper using swww ✅"
    else
        log_error "No supported wallpaper setter found for the current desktop environment ❌"
        return 1
    fi

    return 0
}

# ─── Dispatch ───────────────────────────────────────────────────────────────────

run_ports() {
    local ports=("$@")

    local needs_catppuccin=false
    for port in "${ports[@]}"; do
        if [[ "${port}" != "wallpaper" && "${port}" != "lockscreen" && "${port}" != "loginscreen" ]]; then
            needs_catppuccin=true
            break
        fi
    done

    if [[ "${needs_catppuccin}" == "true" ]]; then
        mkdir -p "${CATPPUCCIN_DIR}"
        log_info "Catppuccin directory: ${CATPPUCCIN_DIR}"
    fi

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
        --lockscreen)
            run_ports "lockscreen"
            ;;
        --loginscreen)
            run_ports "loginscreen"
            ;;
        --micro)
            run_ports "micro"
            ;;
        --mpv)
            run_ports "mpv"
            ;;
        --vim)
            run_ports "vim"
            ;;
        --wallpaper)
            run_ports "wallpaper"
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
